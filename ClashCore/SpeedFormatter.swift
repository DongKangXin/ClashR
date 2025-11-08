//
//  SpeedFormatter.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/23.
//


import Foundation

/// 速度和延迟格式化工具类
public class SpeedFormatter {
    
    private init() {}
    
    // MARK: - 格式化速度（字节/秒）
    
    /// 格式化速度为可读字符串
    /// - Parameter bytesPerSecond: 每秒字节数
    /// - Returns: 格式化后的速度字符串，例如 "5.2 MB/s"
    public static func format(bytesPerSecond: Int) -> String {
        guard bytesPerSecond > 0 else {
            return "0 B/s"
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
    
    // MARK: - 格式化延迟（毫秒）
    
    /// 格式化延迟为可读字符串
    /// - Parameter milliseconds: 延迟毫秒数
    /// - Returns: 格式化后的延迟字符串，例如 "45 ms"
    public static func formatLatency(_ milliseconds: Int) -> String {
        if milliseconds <= 0 {
            return "-- ms"
        }
        
        if milliseconds >= 10000 {
            return "∞ ms"
        }
        
        return "\(milliseconds) ms"
    }
}
