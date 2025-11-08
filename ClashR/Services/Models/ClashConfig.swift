//
//  ClashConfig.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import Foundation
import Yams
import SwiftData




/// 订阅信息模型
 
@Model
public class Subscription: Identifiable {
    public let id = UUID()
    var name: String
    var url: String
    var isExpand: Bool
    var lastUpdate: Date?
    var autoUpdate: Bool
    var createAt = Date()
    var updateInterval: TimeInterval // 自动更新间隔（秒）
    
    init(name: String, url: String) {
        self.name = name
        self.url = url
        self.isExpand = false
        self.lastUpdate = nil
        self.autoUpdate = false
        self.updateInterval = 6 * 60 * 60 // 默认6小时
    }
}

/// 流量统计模型
struct TrafficStats: Codable {
    var uploadBytes: Int64
    var downloadBytes: Int64
    var uploadSpeed: Int64 // 当前上传速度（字节/秒）
    var downloadSpeed: Int64 // 当前下载速度（字节/秒）
    var todayUploadBytes: Int64
    var todayDownloadBytes: Int64
    
    init() {
        self.uploadBytes = 0
        self.downloadBytes = 0
        self.uploadSpeed = 0
        self.downloadSpeed = 0
        self.todayUploadBytes = 0
        self.todayDownloadBytes = 0
    }
    
    /// 格式化字节数为可读字符串
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
    
    /// 格式化速度为可读字符串
    func formatSpeed(_ speed: Int64) -> String {
        return formatBytes(speed) + "/s"
    }
}



/// 日志条目模型
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    
    init(level: LogLevel, message: String) {
        self.timestamp = Date()
        self.level = level
        self.message = message
    }
}

// MARK: - 详细配置数据模型

/// DNS 配置模型
struct DNSConfig: Codable {
    var enable: Bool
    var ipv6: Bool
    var defaultNameserver: [String]
    var fakeIpRange: String
    var useHosts: Bool
    var nameserver: [String]

    init() {
        self.enable = true
        self.ipv6 = false
        self.defaultNameserver = ["223.5.5.5", "119.29.29.29", "180.76.76.76", "1.1.1.1"]
        self.fakeIpRange = "198.18.0.1/16"
        self.useHosts = true
        self.nameserver = ["223.5.5.5", "119.29.29.29"]
    }
}

/// 代理服务器配置模型
struct ProxyConfig: Codable, Identifiable {
    let id = UUID()
    var name: String
    var type: String
    var server: String
    var port: Int
    var password: String?
    var cipher: String?
    var udp: Bool
    var sni: String?
    var skipCertVerify: Bool?

    init(name: String, type: String, server: String, port: Int) {
        self.name = name
        self.type = type
        self.server = server
        self.port = port
        self.password = nil
        self.cipher = nil
        self.udp = true
        self.sni = nil
        self.skipCertVerify = nil
    }
}

/// 代理组配置模型
struct ProxyGroupConfig: Codable, Identifiable {
    let id = UUID()
    var name: String
    var type: String
    var proxies: [String]
    var url: String?
    var interval: Int?

    init(name: String, type: String, proxies: [String]) {
        self.name = name
        self.type = type
        self.proxies = proxies
        self.url = nil
        self.interval = nil
    }
}

