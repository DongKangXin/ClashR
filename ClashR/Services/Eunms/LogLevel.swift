//
//  LogLevel.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/11.
//
import SwiftUI

/// 日志级别枚举
enum LogLevel: String, CaseIterable {
    case all = "all"
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .debug: return "调试"
        case .info: return "信息"
        case .warning: return "警告"
        case .error: return "错误"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return Color.gray
        case .debug: return Color.gray
        case .info: return Color.blue
        case .warning: return Color.orange
        case .error: return Color.red
        }
    }
    // 对应的图标
    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2.fill"  // 网格图标，表示"全部"
        case .debug:
            return "ladybug.fill"          // 调试/bug 相关
        case .info:
            return "info.circle.fill"      // 信息提示
        case .warning:
            return "exclamationmark.triangle.fill" // 警告三角
        case .error:
            return "xmark.circle.fill"     // 错误叉号
        }
    }
}
