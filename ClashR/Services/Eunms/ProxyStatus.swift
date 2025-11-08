//
//  ProxyStatus.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/11.
//
import SwiftUI

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
    
    var color: Color {
        switch self {
        case .disconnected: return Color.gray
        case .connecting: return Color.orange
        case .connected: return Color.green
        case .disconnecting: return Color.orange
        }
    }
}
