//
//  ClashConfig.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import Foundation

/// Clash配置模型
struct ClashConfig: Codable, Identifiable {
    let id: UUID
    var name: String
    var filePath: String
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(name: String, filePath: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.filePath = filePath
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// 代理模式枚举
enum ProxyMode: String, CaseIterable {
    case rule = "Rule"
    case global = "Global"
    case direct = "Direct"
    
    var displayName: String {
        switch self {
        case .rule: return "规则模式"
        case .global: return "全局模式"
        case .direct: return "直连模式"
        }
    }
    
    var icon: String {
        switch self {
        case .rule: return "list.bullet"
        case .global: return "globe"
        case .direct: return "arrow.right"
        }
    }
}

/// 代理状态枚举
enum ProxyStatus {
    case disconnected
    case connecting
    case connected
    case disconnecting
    
    var displayName: String {
        switch self {
        case .disconnected: return "未连接"
        case .connecting: return "连接中"
        case .connected: return "已连接"
        case .disconnecting: return "断开中"
        }
    }
    
    var color: String {
        switch self {
        case .disconnected: return "gray"
        case .connecting: return "orange"
        case .connected: return "green"
        case .disconnecting: return "orange"
        }
    }
}

/// 节点信息模型
struct ProxyNode: Codable, Identifiable {
    let id: String
    var name: String
    var type: String
    var server: String
    var port: Int
    var latency: Int? // 延迟（毫秒）
    var isSelected: Bool
    
    init(id: String, name: String, type: String, server: String, port: Int) {
        self.id = id
        self.name = name
        self.type = type
        self.server = server
        self.port = port
        self.latency = nil
        self.isSelected = false
    }
}

/// 订阅信息模型
struct Subscription: Codable, Identifiable {
    let id: UUID
    var name: String
    var url: String
    var isEnabled: Bool
    var lastUpdate: Date?
    var autoUpdate: Bool
    var updateInterval: TimeInterval // 自动更新间隔（秒）
    
    init(name: String, url: String) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.isEnabled = true
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

/// 日志级别枚举
enum LogLevel: String, CaseIterable {
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
    case debug = "DEBUG"
    
    var color: String {
        switch self {
        case .info: return "blue"
        case .warn: return "orange"
        case .error: return "red"
        case .debug: return "gray"
        }
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
