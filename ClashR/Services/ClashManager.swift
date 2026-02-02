//
//  ClashManager.swift
//  ClashR
//
//  Created by Aone Copilot on 2025/10/16.
//

import Foundation
import Yams
import Combine
import SwiftData

/// 错误类型
public enum ClashManagerError: Error, LocalizedError {
    case invalidYAML
    case fileReadFailed(String)
    case fileWriteFailed(String)
    case invalidPath(String)
    case typeMismatch(String)

    public var errorDescription: String? {
        switch self {
        case .invalidYAML:
            return "YAML 内容不合法或不是期望的字典结构。"
        case .fileReadFailed(let msg):
            return "读取配置文件失败：\(msg)"
        case .fileWriteFailed(let msg):
            return "写入配置文件失败：\(msg)"
        case .invalidPath(let path):
            return "路径不合法：\(path)"
        case .typeMismatch(let msg):
            return "类型不匹配：\(msg)"
        }
    }
}

/// DNS 配置模型（常用字段）
public struct ClashDNS: Codable {
    public var enable: Bool?
    public var ipv6: Bool?
    public var defaultNameserver: [String]?
    public var fakeIpRange: String?
    public var useHosts: Bool?
    public var nameserver: [String]?

    public init(
        enable: Bool? = nil,
        ipv6: Bool? = nil,
        defaultNameserver: [String]? = nil,
        fakeIpRange: String? = nil,
        useHosts: Bool? = nil,
        nameserver: [String]? = nil
    ) {
        self.enable = enable
        self.ipv6 = ipv6
        self.defaultNameserver = defaultNameserver
        self.fakeIpRange = fakeIpRange
        self.useHosts = useHosts
        self.nameserver = nameserver
    }

    public static func fromDict(_ dict: [String: Any]) -> ClashDNS {
        var dns = ClashDNS()
        dns.enable = dict["enable"] as? Bool
        dns.ipv6 = dict["ipv6"] as? Bool
        dns.defaultNameserver = dict["default-nameserver"] as? [String]
        dns.fakeIpRange = dict["fake-ip-range"] as? String
        dns.useHosts = dict["use-hosts"] as? Bool
        dns.nameserver = dict["nameserver"] as? [String]
        return dns
    }

    public func toDict() -> [String: Any] {
        var out: [String: Any] = [:]
        if let v = enable { out["enable"] = v }
        if let v = ipv6 { out["ipv6"] = v }
        if let v = defaultNameserver { out["default-nameserver"] = v }
        if let v = fakeIpRange { out["fake-ip-range"] = v }
        if let v = useHosts { out["use-hosts"] = v }
        if let v = nameserver { out["nameserver"] = v }
        return out
    }
}

/// 代理配置（覆盖常见字段，保留扩展性）
@Model
public class ClashProxy: Equatable,Identifiable {

    public let id = UUID()
    
    public var name: String
    public var type: String
    public var server: String
    public var port: Int

    public var password: String?
    public var cipher: String?
    public var udp: Bool?
    public var sni: String?
    public var skipCertVerify: Bool?
    public var clientFingerprint: String?
    
    public var uuid: String?
    public var alterId: Int?
    public var tls: Bool?
    public var servername: String?
    public var network: String?
    public var wsOpts: String?
    
    public var auth: String?
    public var obfs: String?
    public var obfsPassword:String?
    
    public var delay: Int?
    public var subId: UUID?
    
    
    public var createAt = Date()

    public init(
        name: String,
        type: String,
        server: String,
        port: Int,
        password: String? = nil,
        cipher: String? = nil,
        udp: Bool? = nil,
        sni: String? = nil,
        skipCertVerify: Bool? = nil,
        clientFingerprint: String? = nil,
        
        uuid: String? = nil,
        alterId: Int? = nil,
        tls: Bool? = nil,
        servername: String? = nil,
        network: String? = nil,
        wsOpts: String? = nil,
    
        auth: String? = nil,
        obfs: String? = nil,
        obfsPassword:String? = nil,
    ) {
        self.name = name
        self.type = type
        self.server = server
        self.port = port
        self.password = password
        self.cipher = cipher
        self.udp = udp
        self.sni = sni
        self.skipCertVerify = skipCertVerify
        self.clientFingerprint = clientFingerprint
        
        self.uuid = uuid
        self.alterId = alterId
        self.tls = tls
        self.servername = servername
        self.network = network
        self.wsOpts = wsOpts
        
        self.auth = auth
        self.obfs = obfs;
        self.obfsPassword = obfsPassword
        
    }

    public static func fromDict(_ dict: [String: Any]) -> ClashProxy? {
        guard
            let name = dict["name"] as? String,
            let type = dict["type"] as? String,
            let server = dict["server"] as? String,
            let port = dict["port"] as? Int
        else { return nil }
        var p = ClashProxy(name: name, type: type, server: server, port: port)
        p.password = dict["password"] as? String
        p.cipher = dict["cipher"] as? String
        p.udp = dict["udp"] as? Bool
        p.sni = dict["sni"] as? String
        p.skipCertVerify = dict["skip-cert-verify"] as? Bool
        p.clientFingerprint = dict["client-fingerprint"] as? String
        
        // vmess
        p.uuid = dict["uuid"] as? String
        p.alterId = dict["alterId"] as? Int
        p.tls = dict["tls"] as? Bool
        p.servername = dict["servername"] as? String
        p.network = dict["netword"] as? String
        p.wsOpts = dict["ws-opts"] as? String
        
        //Hysteria2
        p.auth = dict["auth"] as? String
        p.obfs = dict["obfs"] as? String
        p.obfsPassword = dict["obfs-password"] as? String
        
        //Vless
        
        
        return p
    }

    public func toDict() -> [String: Any] {
        var out: [String: Any] = [:]
        out["name"] = name
        out["type"] = type
        out["server"] = server
        out["port"] = port
        if let v = password { out["password"] = v }
        if let v = cipher { out["cipher"] = v }
        if let v = udp { out["udp"] = v }
        if let v = sni { out["sni"] = v }
        if let v = skipCertVerify { out["skip-cert-verify"] = v }
        if let v = clientFingerprint { out["client-fingerprint"] = v }

        if let v = uuid { out["uuid"] = v }
        if let v = alterId { out["alterId"] = v }
        if let v = tls { out["tls"] = v }
        if let v = servername { out["servername"] = v }
        if let v = network { out["network"] = v }
        if let v = wsOpts { out["ws-opts"] = v }

        if let v = auth { out["auth"] = v }
        if let v = obfs { out["obfs"] = v }
        if let v = obfsPassword { out["obfs-password"] = v }

        return out
    }
}

/// 代理组配置（常用字段）
public struct ClashProxyGroup: Codable, Equatable {
    public var name: String
    public var type: String
    public var proxies: [String]
    public var url: String?
    public var interval: Int?

    public init(name: String, type: String, proxies: [String], url: String? = nil, interval: Int? = nil) {
        self.name = name
        self.type = type
        self.proxies = proxies
        self.url = url
        self.interval = interval
    }

    public static func fromDict(_ dict: [String: Any]) -> ClashProxyGroup? {
        guard
            let name = dict["name"] as? String,
            let type = dict["type"] as? String,
            let proxies = dict["proxies"] as? [String]
        else { return nil }
        var g = ClashProxyGroup(name: name, type: type, proxies: proxies)
        g.url = dict["url"] as? String
        g.interval = dict["interval"] as? Int
        return g
    }

    public func toDict() -> [String: Any] {
        var out: [String: Any] = [:]
        out["name"] = name
        out["type"] = type
        out["proxies"] = proxies
        if let v = url { out["url"] = v }
        if let v = interval { out["interval"] = v }
        return out
    }
}

/// 通用配置管理器：
/// - 支持通过 API 读写常见字段
/// - 支持通用路径式 get/set（如 "dns.enable"、"proxies[0].name"）
/// - 支持从 YAML 加载与写回
public class ClashManager: ObservableObject {
    
    static let share = ClashManager()

    /// 原始配置字典（完整 YAML 映射）
    @Published public private(set) var raw: [String: Any] = [:]

    /// 当前是否已从文件加载
    @Published public private(set) var isLoaded: Bool = false

    /// 推荐统一写入的文件名
    public static let defaultFileName = "config.yaml"

    public init() {}

    // MARK: - YAML I/O

    /// 从 YAML 字符串加载
    @discardableResult
    public func load(fromYAML yaml: String) throws -> [String: Any] {
        let any = try Yams.load(yaml: yaml)
        guard let dict = any as? [String: Any] else {
            throw ClashManagerError.invalidYAML
        }
        raw = dict
        isLoaded = true
        return dict
    }

    /// 从共享配置文件夹读取（默认 config.yml）
    @discardableResult
    public func loadFromFile(fileName: String = ClashManager.defaultFileName) -> Result<[String: Any], Error> {
        guard let yaml = FileUtils.readContentFromFile(subpath: ClashManager.defaultFileName) else {
            return .failure(ClashManagerError.fileReadFailed("文件读取失败：" + ClashManager.defaultFileName))
        }
        do {
            let dict = try load(fromYAML: yaml)
            return .success(dict)
        } catch {
            return .failure(error)
        }
    }

    /// 转为 YAML 字符串
    public func toYAML() throws -> String {
        return try unescapeYAMLEmoji(Yams.dump(object: raw, allowUnicode: true))
    }
    
    private func unescapeYAMLEmoji(_ text: String) -> String {
        let pattern = #"\\U([0-9A-Fa-f]{8})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        var result = ""
        var lastEnd = 0
        
        regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match = match else { return }
            
            // 1. 添加匹配前的原始文本
            let matchRange = match.range
            if matchRange.location > lastEnd {
                result += nsString.substring(with: NSRange(location: lastEnd, length: matchRange.location - lastEnd))
            }
            
            // 2. 解析 \U 后的 8 位十六进制码点
            let hexRange = match.range(at: 1)
            let hexString = nsString.substring(with: hexRange)
            if let code = UInt32(hexString, radix: 16),
               let scalar = UnicodeScalar(code) {
                result += String(scalar)
            } else {
                // 解析失败，保留原转义序列
                result += nsString.substring(with: matchRange)
            }
            
            // 3. 更新 lastEnd
            lastEnd = matchRange.location + matchRange.length
        }
        
        // 4. 添加最后一段未匹配的文本
        if lastEnd < nsString.length {
            result += nsString.substring(from: lastEnd)
        }
        
        return result
    }

    /// 写入到共享配置文件夹（默认 config.yml）
    @discardableResult
    public func saveToFile(fileName: String = ClashManager.defaultFileName) -> Result<Void, Error> {
 
        do{
            let yaml = try toYAML()
            _ = FileUtils.writeContentToFile(subpath: fileName, content: yaml,force: true)
            return .success(())
        } catch {
            return .failure(ClashManagerError.fileWriteFailed("文件写入失败：" + ClashManager.defaultFileName))
        }
            
    }

    // MARK: - 常见字段 API（便捷方法）

    public var mixedPort: Int {
        get { raw["mixed-port"] as? Int ?? 0}
        set { raw["mixed-port"] = newValue }
    }

    public var allowLan: Bool {
        get { raw["allow-lan"] as? Bool ?? false }
        set { raw["allow-lan"] = newValue }
    }
    
    public var ipv6: Bool {
        get { raw["ipv6"] as? Bool ?? false }
        set { raw["ipv6"] = newValue }
    }

    public var bindAddress: String {
        get { raw["bind-address"] as? String ?? "127.0.0.1" }
        set { raw["bind-address"] = newValue }
    }

    public func setMode(_ mode: String){
        raw["mode"] = mode
    }
    
    public func setLogLevel(_ level: String){
        raw["log-level"] = level
    }
    
//    public var mode: String {
//        get { raw["mode"] as? String ?? "rule" }
//        set { raw["mode"] = newValue }
//    }

//    public var logLevel: String {
//        get { raw["log-level"] as? String ?? "error" }
//        set { raw["log-level"] = newValue }
//    }

    public var externalController: String {
        get { raw["external-controller"] as? String ?? "127.0.0.1:9090" }
        set { raw["external-controller"] = newValue }
    }

    // MARK: - DNS

    public func getDNS() -> ClashDNS {
        guard let dnsDict = raw["dns"] as? [String: Any] else { return ClashDNS() }
        return ClashDNS.fromDict(dnsDict) ?? ClashDNS()
    }

    public func setDNS(_ dns: ClashDNS) {
        raw["dns"] = dns.toDict()
    }

    // MARK: - Proxies

    public func listProxies() -> [ClashProxy] {
        guard let arr = raw["proxies"] as? [[String: Any]] else { return [] }
        return arr.compactMap { ClashProxy.fromDict($0) }
    }

    public func setProxies(_ proxies: [ClashProxy]) {
        raw["proxies"] = proxies.map { $0.toDict() }
    }

    public func addProxy(_ proxy: ClashProxy) {
        var arr = (raw["proxies"] as? [[String: Any]]) ?? []
        arr.append(proxy.toDict())
        raw["proxies"] = arr
    }

    public func updateProxy(_ proxy: ClashProxy) {
        var arr = (raw["proxies"] as? [[String: Any]]) ?? []
        if let idx = arr.firstIndex(where: { ($0["name"] as? String) == proxy.name }) {
            arr[idx] = proxy.toDict()
        } else {
            arr.append(proxy.toDict())
        }
        raw["proxies"] = arr
    }

    public func removeProxy(named name: String) {
        var arr = (raw["proxies"] as? [[String: Any]]) ?? []
        arr.removeAll { ($0["name"] as? String) == name }
        raw["proxies"] = arr
    }

    // MARK: - Proxy Groups
    
    public func setAutoProxyNames(_ proxies : [String]) {
        guard var arr = raw["proxy-groups"] as? [[String: Any]] else { return }
        if let idx = arr.firstIndex(where: { ($0["name"] as? String) == "AUTO" }) {
            arr[idx]["proxies"] = proxies
        }
        raw["proxy-groups"] = arr
            
    }
    
    public func setUserProxieName(_ name: String){
        guard var arr = raw["proxy-groups"] as? [[String: Any]] else { return }
        if let idx = arr.firstIndex(where: { ($0["name"] as? String) == "USER" }) {
            arr[idx]["proxies"] = [name]
        }
    }

    public func listProxyGroups() -> [ClashProxyGroup] {
        guard let arr = raw["proxy-groups"] as? [[String: Any]] else { return [] }
        return arr.compactMap { ClashProxyGroup.fromDict($0) }
    }

    public func setProxyGroups(_ groups: [ClashProxyGroup]) {
        raw["proxy-groups"] = groups.map { $0.toDict() }
    }

    public func addProxyGroup(_ group: ClashProxyGroup) {
        var arr = (raw["proxy-groups"] as? [[String: Any]]) ?? []
        arr.append(group.toDict())
        raw["proxy-groups"] = arr
    }

    public func updateProxyGroup(_ group: ClashProxyGroup) {
        var arr = (raw["proxy-groups"] as? [[String: Any]]) ?? []
        if let idx = arr.firstIndex(where: { ($0["name"] as? String) == group.name }) {
            arr[idx] = group.toDict()
        } else {
            arr.append(group.toDict())
        }
        raw["proxy-groups"] = arr
    }

    public func removeProxyGroup(named name: String) {
        var arr = (raw["proxy-groups"] as? [[String: Any]]) ?? []
        arr.removeAll { ($0["name"] as? String) == name }
        raw["proxy-groups"] = arr
    }

    // MARK: - Rules

    public func getRules() -> [String] {
        (raw["rules"] as? [String]) ?? []
    }

    public func setRules(_ rules: [String]) {
        raw["rules"] = rules
    }

    public func appendRule(_ rule: String) {
        var r = (raw["rules"] as? [String]) ?? []
        r.append(rule)
        raw["rules"] = r
    }

    public func removeRule(_ rule: String) {
        var r = (raw["rules"] as? [String]) ?? []
        r.removeAll { $0 == rule }
        raw["rules"] = r
    }

    // MARK: - 通用路径式 API
    // 允许通过路径操作任意键，如：
    // set(at: "dns.enable", to: true)
    // set(at: "proxies[0].name", to: "node-1")
    // get(at: "proxy-groups[1].interval")

    public func get(at path: String) -> Any? {
        return ClashManager.getValue(for: path, in: raw)
    }

    public func set(at path: String, to value: Any) throws {
        raw = try ClashManager.setValue(for: path, in: raw, to: value)
    }

    // MARK: - 路径解析与读写实现

    private struct PathToken {
        let key: String
        let index: Int? // 若存在 [index] 则非空
    }

    private static func tokenize(_ path: String) -> [PathToken] {
        // 支持 key[index] 与 key 的混合，分隔符为 "."
        return path.split(separator: ".").map { segment in
            let s = String(segment)
            if let lb = s.firstIndex(of: "["), let rb = s.firstIndex(of: "]"), lb < rb {
                let key = String(s[..<lb])
                let idxStr = String(s[s.index(after: lb)..<rb])
                if let idx = Int(idxStr) {
                    return PathToken(key: key, index: idx)
                }
                return PathToken(key: key, index: nil)
            } else {
                return PathToken(key: s, index: nil)
            }
        }
    }

    private static func getValue(for path: String, in root: [String: Any]) -> Any? {
        let tokens = tokenize(path)
        var current: Any = root
        for t in tokens {
            if let dict = current as? [String: Any] {
                guard var next: Any = dict[t.key] else { return nil }
                if let index = t.index {
                    guard let arr = next as? [Any], arr.indices.contains(index) else { return nil }
                    next = arr[index]
                }
                current = next
            } else if let arr = current as? [Any] {
                guard let index = t.index, arr.indices.contains(index) else { return nil }
                current = arr[index]
            } else {
                return nil
            }
        }
        return current
    }

    private static func setValue(for path: String, in root: [String: Any], to value: Any) throws -> [String: Any] {
        var rootCopy = root
        let tokens = tokenize(path)
        guard !tokens.isEmpty else {
            throw ClashManagerError.invalidPath(path)
        }

        func setRec(_ idx: Int, current: inout Any) throws {
            let t = tokens[idx]
            if idx == tokens.count - 1 {
                // 最后一个 token，执行写入
                if var dict = current as? [String: Any] {
                    if let arrayIndex = t.index {
                        var arr = (dict[t.key] as? [Any]) ?? []
                        // 扩容或覆盖
                        if arrayIndex >= arr.count {
                            // 用 nil 填充到目标索引之前（或直接追加）
                            while arr.count < arrayIndex {
                                arr.append(NSNull())
                            }
                            arr.append(value)
                        } else {
                            arr[arrayIndex] = value
                        }
                        dict[t.key] = arr
                        current = dict
                    } else {
                        dict[t.key] = value
                        current = dict
                    }
                } else if var arr = current as? [Any] {
                    // 直接数组场景，仅当 t.index 有效
                    guard let arrayIndex = t.index, arr.indices.contains(arrayIndex) else {
                        throw ClashManagerError.invalidPath("数组索引越界或无 key：\(path)")
                    }
                    arr[arrayIndex] = value
                    current = arr
                } else {
                    throw ClashManagerError.invalidPath("无法在非容器类型上设置值：\(path)")
                }
                return
            }

            // 不是最后一个 token，继续向下
            if var dict = current as? [String: Any] {
                var next: Any = dict[t.key] ?? [:]
                if let arrayIndex = t.index {
                    var arr = (next as? [Any]) ?? []
                    if arrayIndex >= arr.count {
                        // 扩容并填充空
                        while arr.count <= arrayIndex {
                            arr.append([String: Any]())
                        }
                    }
                    var child = arr[arrayIndex]
                    try setRec(idx + 1, current: &child)
                    arr[arrayIndex] = child
                    dict[t.key] = arr
                } else {
                    try setRec(idx + 1, current: &next)
                    dict[t.key] = next
                }
                current = dict
            } else if var arr = current as? [Any] {
                guard let arrayIndex = t.index, arr.indices.contains(arrayIndex) else {
                    throw ClashManagerError.invalidPath("数组索引越界或无 key：\(path)")
                }
                var child = arr[arrayIndex]
                try setRec(idx + 1, current: &child)
                arr[arrayIndex] = child
                current = arr
            } else {
                throw ClashManagerError.invalidPath("无法在非容器类型上设置值：\(path)")
            }
        }

        var current: Any = rootCopy
        try setRec(0, current: &current)
        if let dict = current as? [String: Any] {
            return dict
        }
        throw ClashManagerError.invalidPath("根节点被置为非字典：\(path)")
    }
    
    func readLogFile() -> String {
        return FileUtils.readContentFromFile(subpath: "logs/clash.log") ?? ""
    }
    
    func readConfigFile() -> String {
        return unescapeYAMLEmoji(FileUtils.readContentFromFile(subpath: "config.yaml") ?? "")
    }
    
    func backDefault() throws {
        _ = FileUtils.copyFileFromBundle(fileName: "config.yaml", toSubpath: ClashManager.defaultFileName,force: true)
        self.loadFromFile()
    }
    
    func loadFromDefault(){
        _ = FileUtils.copyFileFromBundle(fileName: "config.yaml", toSubpath: ClashManager.defaultFileName,force: true)
        self.loadFromFile()
    }
}
