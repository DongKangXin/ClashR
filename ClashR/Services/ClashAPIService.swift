//
//  ClashAPIService.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/5.
//

import Foundation
import Combine

/// Clash HTTP API 服务类
@MainActor
class ClashAPIService: ObservableObject {
    
    static let shared = ClashAPIService()
    lazy var vpnManager = VPNManager.share
    
    // MARK: - Properties
    private let baseURL = "http://127.0.0.1:9090"
    private let secret = "" // 从配置中读取
    private var cancellables = Set<AnyCancellable>()
    private var logStreamClient: StreamClient<ClashLogEntry>?
    private var trafficStreamClient: StreamClient<TrafficInfo>?


    
    // MARK: - Published Properties
    @Published var logs: [ClashLogEntry] = []
    @Published var traffic: TrafficInfo?
    var lastStart: Date = Date()
    var trafficList: [TrafficInfo] = []
    @Published var trafficSecond: TrafficInfo?
    
    @Published var memory: MemoryInfo?
    @Published var version: String?
    @Published var proxies: [String: ProxyInfo] = [:]
    @Published var proxyGroups: [String: ProxyGroupInfo] = [:]
    @Published var connections: [ConnectionInfo] = []
    
    // MARK: - Initialization
    private init() {
    }
    
    // MARK: - Private Methods
    
    /// 创建请求头
    private func createHeaders() -> [String: String] {
        var headers = ["Content-Type": "application/json"]
        if !secret.isEmpty {
            headers["Authorization"] = "Bearer \(secret)"
        }
        return headers
    }
    
    /// 执行HTTP请求
    private func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T? {
        if(vpnManager.connect != .connected){
            return nil
        }
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw ClashAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = createHeaders()
        
        if let body = body {
            request.httpBody = body
        }
        
        do {
            print("✅ 调用开始:")
            let (data, response) = try await URLSession.shared.data(for: request)
            print("✅ 成功: \(data.count) bytes")
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClashAPIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw ClashAPIError.httpError(httpResponse.statusCode)
            }
            
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw ClashAPIError.decodingError(error)
            }
        } catch {
            if error is CancellationError {
                print("⚠️ Task 被取消了！")
            } else {
                print("❌ 网络错误: \(error)")
            }
        }
        return nil
        
    }
    
    // MARK: - Log Methods
    
    /// 添加日志
    func addLog(level: String, message: String) {
        let logEntry = ClashLogEntry(type: level, payload: message)
        logs.append(logEntry)
        
        // 限制日志数量，避免内存过多占用
        if logs.count > 1000 {
            logs.removeFirst(100)
        }
    }
    
    /// 开始日志流
    func startLogStreaming() {
        guard logStreamClient == nil else { return }
        logs.removeAll()
        guard let url = URL(string: "http://127.0.0.1:9090/logs") else {
            addLog(level: "warn",message: "日志断开: url 错误")
            return
        }
        logStreamClient = StreamClient<ClashLogEntry>(url: url)
        _ = logStreamClient?.start(onEvent: {[weak self] log in
            self?.logs.append(log)
        }, onComplete: {[weak self]  error in
            if let error = error {
                self?.addLog(level: "warn",message: "日志断开: " + error.localizedDescription)
            }
            
        })
    }
    
    //关闭日志流
    func stopLogStream(){
        guard logStreamClient != nil else { return }
        logStreamClient = nil
        
    }
    
    
    /// 清空日志
    func clearLogs() {
        logs.removeAll()
    }
    
    // MARK: - Traffic Methods
    
    /// 开始流量监控
    public func startTrafficMonitoring() {
        guard trafficStreamClient == nil else { return }
        
        guard let url = URL(string: "http://127.0.0.1:9090/traffic") else {
            return
        }
        trafficStreamClient = StreamClient<TrafficInfo>(url: url)
        _ = trafficStreamClient?.start(onEvent: {[weak self] traffic in
            guard self != nil  else {return}
            self?.traffic = traffic
            self?.trafficList.append(traffic)
            let lastStartTime = self?.lastStart.timeIntervalSince1970 ?? Double(0)
            if Date().timeIntervalSince1970 - lastStartTime > 1 {
                var up = 0
                var down = 0
                self?.trafficList.forEach{
                    up += $0.up
                    down += $0.down
                }
                self?.trafficList.removeAll()
                self?.lastStart = Date()
                self?.trafficSecond = TrafficInfo(up: up, down: down)
            }
        }, onComplete: {[weak self]  error in
            if let error = error {
            }
        })
    }
    //关闭流量监控
    func stopTrafficMonitoring(){
        guard logStreamClient != nil else { return }
        logStreamClient = nil
        
    }
    
    
    // MARK: - Memory Methods
    
    /// 获取内存信息
    func fetchMemory() async {
        do {
            memory = try await performRequest(
                endpoint: "/memory",
                responseType: MemoryInfo.self
            )
        } catch {
            print("获取内存信息失败: \(error)")
        }
    }
    
    // MARK: - Version Methods
    
    /// 获取版本信息
    func fetchVersion() async {
        do {
            version = try await performRequest(
                endpoint: "/version",
                responseType: String.self
            )
        } catch {
            print("获取版本信息失败: \(error)")
        }
    }
    
    // MARK: - Config Methods
    
   
    
    /// 重新加载配置
    func reloadConfigs(force: Bool = true) async throws {
        let endpoint = force ? "/configs?force=true" : "/configs"
        let body = try JSONSerialization.data(withJSONObject: ["path": "", "payload": ""])
        
        try await performRequest(
            endpoint: endpoint,
            method: .PUT,
            body: body,
            responseType: EmptyResponse.self
        )
    }
    
    /// 更新配置
    func updateConfigs(_ config: [String: Any]) async throws {
        let body = try JSONSerialization.data(withJSONObject: config)
        
        try await performRequest(
            endpoint: "/configs",
            method: .PATCH,
            body: body,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Proxy Methods
    
    /// 获取代理信息
    func fetchProxies() async {
        do {
            try await performRequest(
                endpoint: "/proxies",
                responseType: ProxiesResponse.self
            )
        } catch {
            print("获取代理信息失败: \(error)")
        }
    }
    
    /// 选择代理
    func selectProxy(proxyName: String, selectedProxy: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["name": selectedProxy])
        
        try await performRequest(
            endpoint: "/proxies/\(proxyName)",
            method: .PUT,
            body: body,
            responseType: EmptyResponse.self
        )
    }
    
    /// 测试代理延迟
    func testProxyDelay(proxyName: String, url: String = "http://www.google.com", timeout: Int = 5000) async throws -> DelayInfo {
        let endpoint = baseURL + "/proxies/\(proxyName)/delay?url=\(url)&timeout=\(timeout)"
        // 创建 HTTP 客户端
        let client = HTTPClient<DelayInfo>()
        
        // 调用 Clash API
        return try await client.get(endpoint) ?? DelayInfo(delay: 999)
    }
    
    // MARK: - Proxy Group Methods
    
    /// 获取代理组信息
    func fetchProxyGroups() async {
//        do {
//            let response: ProxyGroupsResponse = try await performRequest(
//                endpoint: "/group",
//                responseType: ProxyGroupsResponse.self
//            )
//            proxyGroups = response.proxyGroups
//        } catch {
//            print("获取代理组信息失败: \(error)")
//        }
    }
    
    /// 测试代理组延迟
    func testProxyGroupDelay(groupName: String, url: String = "http://cp.cloudflare.com/", timeout: Int = 5000) async throws -> DelayInfo {
        let endpoint = "/group/\(groupName)/delay?url=\(url)&timeout=\(timeout)"
        return try await performRequest(
            endpoint: endpoint,
            responseType: DelayInfo.self
        ) ?? DelayInfo(delay: 999)
    }
    
    // MARK: - Connection Methods
    
    /// 获取连接信息
    func fetchConnections() async {
        do {
            connections = try await performRequest(
                endpoint: "/connections",
                responseType: [ConnectionInfo].self
            ) ?? []
        } catch {
            print("获取连接信息失败: \(error)")
        }
    }
    
    /// 关闭所有连接
    func closeAllConnections() async throws {
        try await performRequest(
            endpoint: "/connections",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
    }
    
    /// 关闭特定连接
    func closeConnection(id: String) async throws {
        try await performRequest(
            endpoint: "/connections/\(id)",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Cache Methods
    
    /// 清除FakeIP缓存
    func flushFakeIPCache() async throws {
        try await performRequest(
            endpoint: "/cache/fakeip/flush",
            method: .POST,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Restart Methods
    
    /// 重启内核
    func restart() async throws {
        try await performRequest(
            endpoint: "/restart",
            method: .POST,
            responseType: EmptyResponse.self
        )
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

enum ClashAPIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
}

struct EmptyResponse: Codable {}

// MARK: - Data Models

/// Clash日志条目
struct ClashLogEntry: Codable, Identifiable {
    let id = UUID()
    let type: String
    let payload: String
    let time: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case type, payload, time
    }
}



/// 内存信息
struct MemoryInfo: Codable {
    let inuse: Int64
    let oslimit: Int64
}

/// 配置信息
struct ConfigInfo: Codable {
    let port: Int
    let socksPort: Int
    let redirPort: Int
    let tproxyPort: Int
    let mixedPort: Int
    let allowLan: Bool
    let bindAddress: String
    let mode: String
    let logLevel: String
    let ipv6: Bool
}

/// 代理信息
struct ProxyInfo: Codable {
    let name: String
    let type: String
    let all: [String]?
    let now: String?
    let delay: Int?
    let history: [DelayHistory]?
}

/// 代理组信息
struct ProxyGroupInfo: Codable {
    let name: String
    let type: String
    let all: [String]
    let now: String
    let delay: Int?
    let history: [DelayHistory]?
}

/// 延迟历史
struct DelayHistory: Codable {
    let time: String
    let delay: Int
}

/// 延迟信息
struct DelayInfo: Codable {
    let delay: Int
}

/// 连接信息
struct ConnectionInfo: Codable, Identifiable {
    let id: String
    let metadata: ConnectionMetadata
    let upload: Int64
    let download: Int64
    let start: String
    let chains: [String]
    let rule: String
}

/// 连接元数据
struct ConnectionMetadata: Codable {
    let network: String
    let type: String
    let sourceIP: String
    let destinationIP: String
    let sourcePort: String
    let destinationPort: String
    let host: String
    let dnsMode: String
    
    enum CodingKeys: String, CodingKey {
        case network, type, host, dnsMode
        case sourceIP = "sourceIP"
        case destinationIP = "destinationIP"
        case sourcePort = "sourcePort"
        case destinationPort = "destinationPort"
    }
}

/// 代理响应
struct ProxiesResponse: Codable {
    let proxies: [String: ProxyInfo]
}

/// 代理组响应
struct ProxyGroupsResponse: Codable {
    let proxyGroups: [String: ProxyGroupInfo]
    
    enum CodingKeys: String, CodingKey {
        case proxyGroups = "proxy-groups"
    }
}
