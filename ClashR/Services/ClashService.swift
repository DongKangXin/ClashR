//
//  ClashService.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import Foundation
import Combine
import NetworkExtension

/// Clash核心服务类
@MainActor
class ClashService: ObservableObject {
    // MARK: - Published Properties
    @Published var proxyStatus: ProxyStatus = .disconnected
    @Published var currentMode: ProxyMode = .rule
    @Published var currentConfig: ClashConfig?
    @Published var proxyNodes: [ProxyNode] = []
    @Published var trafficStats = TrafficStats()
    @Published var logs: [LogEntry] = []
    @Published var selectedLogLevel: LogLevel = .info
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let configManager = ConfigManager()
    private let subscriptionManager = SubscriptionManager()
    private var trafficTimer: Timer?
    private var logTimer: Timer?
    
    // MARK: - Initialization
    init() {
        setupTrafficMonitoring()
        setupLogMonitoring()
        loadCurrentConfig()
    }
    
    deinit {
        trafficTimer?.invalidate()
        logTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// 启动代理服务
    func startProxy() async {
        guard let config = currentConfig else {
            addLog(level: .error, message: "没有可用的配置")
            return
        }
        
        proxyStatus = .connecting
        addLog(level: .info, message: "正在启动代理服务...")
        
        do {
            // TODO: 集成Clash内核启动逻辑
            // 这里需要调用Clash xcframework的C接口
            try await startClashCore(configPath: config.filePath)
            
            proxyStatus = .connected
            addLog(level: .info, message: "代理服务启动成功")
            
            // 开始监控流量
            startTrafficMonitoring()
            
        } catch {
            proxyStatus = .disconnected
            addLog(level: .error, message: "代理服务启动失败: \(error.localizedDescription)")
        }
    }
    
    /// 停止代理服务
    func stopProxy() async {
        proxyStatus = .disconnecting
        addLog(level: .info, message: "正在停止代理服务...")
        
        do {
            // TODO: 调用Clash内核停止接口
            try await stopClashCore()
            
            proxyStatus = .disconnected
            addLog(level: .info, message: "代理服务已停止")
            
            // 停止流量监控
            stopTrafficMonitoring()
            
        } catch {
            proxyStatus = .connected
            addLog(level: .error, message: "停止代理服务失败: \(error.localizedDescription)")
        }
    }
    
    /// 切换代理模式
    func switchMode(to mode: ProxyMode) async {
        guard proxyStatus == .connected else {
            addLog(level: .warn, message: "代理未连接，无法切换模式")
            return
        }
        
        currentMode = mode
        addLog(level: .info, message: "切换到\(mode.displayName)")
        
        // TODO: 发送模式切换指令给Clash内核
        do {
            try await setClashMode(mode.rawValue)
        } catch {
            addLog(level: .error, message: "模式切换失败: \(error.localizedDescription)")
        }
    }
    
    /// 选择节点
    func selectNode(_ node: ProxyNode) async {
        guard proxyStatus == .connected else {
            addLog(level: .warn, message: "代理未连接，无法切换节点")
            return
        }
        
        // 更新节点选择状态
        proxyNodes.indices.forEach { index in
            proxyNodes[index].isSelected = (proxyNodes[index].id == node.id)
        }
        
        addLog(level: .info, message: "切换到节点: \(node.name)")
        
        // TODO: 发送节点切换指令给Clash内核
        do {
            try await setClashNode(nodeId: node.id)
        } catch {
            addLog(level: .error, message: "节点切换失败: \(error.localizedDescription)")
        }
    }
    
    /// 测试节点延迟
    func testNodeLatency(_ node: ProxyNode) async {
        addLog(level: .info, message: "正在测试节点 \(node.name) 的延迟...")
        
        do {
            let latency = try await performLatencyTest(server: node.server, port: node.port)
            
            // 更新节点延迟
            if let index = proxyNodes.firstIndex(where: { $0.id == node.id }) {
                proxyNodes[index].latency = latency
            }
            
            addLog(level: .info, message: "节点 \(node.name) 延迟: \(latency)ms")
            
        } catch {
            addLog(level: .error, message: "延迟测试失败: \(error.localizedDescription)")
        }
    }
    
    /// 切换配置
    func switchConfig(to config: ClashConfig) async {
        guard proxyStatus == .disconnected else {
            addLog(level: .warn, message: "请先停止代理服务再切换配置")
            return
        }
        
        currentConfig = config
        addLog(level: .info, message: "切换到配置: \(config.name)")
        
        // 重新加载节点列表
        await loadProxyNodes()
    }
    
    /// 清空今日流量统计
    func clearTodayTraffic() {
        trafficStats.todayUploadBytes = 0
        trafficStats.todayDownloadBytes = 0
        addLog(level: .info, message: "已清空今日流量统计")
    }
    
    /// 清空日志
    func clearLogs() {
        logs.removeAll()
        addLog(level: .info, message: "日志已清空")
    }
    
    // MARK: - Private Methods
    
    /// 加载当前配置
    private func loadCurrentConfig() {
        currentConfig = configManager.getDefaultConfig()
        Task {
            await loadProxyNodes()
        }
    }
    
    /// 加载代理节点列表
    func loadProxyNodes() async {
        guard let config = currentConfig else { return }
        
        do {
            // TODO: 从Clash内核获取节点列表
            let nodes = try await getClashNodes(configPath: config.filePath)
            proxyNodes = nodes
        } catch {
            addLog(level: .error, message: "加载节点列表失败: \(error.localizedDescription)")
        }
    }
    
    /// 设置流量监控
    private func setupTrafficMonitoring() {
        // 每分钟更新一次流量统计
        trafficTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateTrafficStats()
            }
        }
    }
    
    /// 设置日志监控
    private func setupLogMonitoring() {
        // 每5秒检查一次新日志
        logTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchNewLogs()
            }
        }
    }
    
    /// 开始流量监控
    private func startTrafficMonitoring() {
        trafficTimer?.fire()
    }
    
    /// 停止流量监控
    private func stopTrafficMonitoring() {
        trafficStats.uploadSpeed = 0
        trafficStats.downloadSpeed = 0
    }
    
    /// 更新流量统计
    private func updateTrafficStats() async {
        guard proxyStatus == .connected else { return }
        
        do {
            // TODO: 从Clash内核获取流量统计
            let stats = try await getClashTrafficStats()
            
            trafficStats.uploadBytes = stats.uploadBytes
            trafficStats.downloadBytes = stats.downloadBytes
            trafficStats.uploadSpeed = stats.uploadSpeed
            trafficStats.downloadSpeed = stats.downloadSpeed
            
            // 更新今日流量（简化处理，实际应该更精确）
            trafficStats.todayUploadBytes += stats.uploadSpeed
            trafficStats.todayDownloadBytes += stats.downloadSpeed
            
        } catch {
            addLog(level: .error, message: "获取流量统计失败: \(error.localizedDescription)")
        }
    }
    
    /// 获取新日志
    private func fetchNewLogs() async {
        guard proxyStatus == .connected else { return }
        
        do {
            // TODO: 从Clash内核获取新日志
            let newLogs = try await getClashLogs()
            
            for log in newLogs {
                addLog(level: log.level, message: log.message)
            }
            
        } catch {
            // 静默处理日志获取错误
        }
    }
    
    /// 添加日志条目
    private func addLog(level: LogLevel, message: String) {
        let logEntry = LogEntry(level: level, message: message)
        logs.append(logEntry)
        
        // 限制日志数量，避免内存过多占用
        if logs.count > 1000 {
            logs.removeFirst(100)
        }
    }
    
    // MARK: - Clash Core Integration (TODO)
    
    /// 启动Clash内核
    private func startClashCore(configPath: String) async throws {
        // TODO: 集成Clash xcframework
        // 这里需要调用C接口启动Clash内核
        try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟延迟
    }
    
    /// 停止Clash内核
    private func stopClashCore() async throws {
        // TODO: 调用C接口停止Clash内核
        try await Task.sleep(nanoseconds: 500_000_000) // 模拟延迟
    }
    
    /// 设置Clash模式
    private func setClashMode(_ mode: String) async throws {
        // TODO: 发送模式切换指令
        try await Task.sleep(nanoseconds: 100_000_000) // 模拟延迟
    }
    
    /// 设置Clash节点
    private func setClashNode(nodeId: String) async throws {
        // TODO: 发送节点切换指令
        try await Task.sleep(nanoseconds: 100_000_000) // 模拟延迟
    }
    
    /// 获取Clash节点列表
    private func getClashNodes(configPath: String) async throws -> [ProxyNode] {
        // TODO: 从Clash内核获取节点列表
        try await Task.sleep(nanoseconds: 200_000_000) // 模拟延迟
        
        // 返回模拟数据
        return [
            ProxyNode(id: "node1", name: "香港节点1", type: "ss", server: "hk1.example.com", port: 443),
            ProxyNode(id: "node2", name: "美国节点1", type: "ss", server: "us1.example.com", port: 443),
            ProxyNode(id: "node3", name: "日本节点1", type: "ss", server: "jp1.example.com", port: 443)
        ]
    }
    
    /// 获取Clash流量统计
    private func getClashTrafficStats() async throws -> TrafficStats {
        // TODO: 从Clash内核获取流量统计
        try await Task.sleep(nanoseconds: 100_000_000) // 模拟延迟
        
        // 返回模拟数据
        var stats = TrafficStats()
        stats.uploadBytes = Int64.random(in: 1000000...10000000)
        stats.downloadBytes = Int64.random(in: 10000000...100000000)
        stats.uploadSpeed = Int64.random(in: 1000...10000)
        stats.downloadSpeed = Int64.random(in: 10000...100000)
        return stats
    }
    
    /// 获取Clash日志
    private func getClashLogs() async throws -> [LogEntry] {
        // TODO: 从Clash内核获取日志
        try await Task.sleep(nanoseconds: 50_000_000) // 模拟延迟
        
        // 返回空数组（模拟无新日志）
        return []
    }
    
    /// 执行延迟测试
    private func performLatencyTest(server: String, port: Int) async throws -> Int {
        // TODO: 实现真实的延迟测试
        try await Task.sleep(nanoseconds: 200_000_000) // 模拟延迟
        
        // 返回模拟延迟数据
        return Int.random(in: 50...300)
    }
}
