//
//  ClashService.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import Foundation
import Combine
import NetworkExtension
import Mihomo

/// Clash核心服务类

class ClashService: ObservableObject {
    
    static let share = ClashService()
    
    // MARK: - Published Properties
    @Published var currentMode: ProxyMode = .rule
    @Published var logs: [LogEntry] = []
    @Published var selectedLogLevel: LogLevel = .info

    // MARK: - Initialization
    init() {
    }
    
    // MARK: - Public Methods
    
    /// 添加日志
    func addLog(level: LogLevel, message: String) {
        let logEntry = LogEntry(level: level, message: message)
        logs.append(logEntry)
        
        // 限制日志数量，避免内存过多占用
        if logs.count > 1000 {
            logs.removeFirst(100)
        }
    }
    
    /// 清空日志
    func clearLogs() {
        logs.removeAll()
    }
    

}
