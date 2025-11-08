//
//  DarwinNotification.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/24.
//

import Foundation

struct DarwinNotificationSender {
    
    static let share = DarwinNotificationSender()
    
    public static let appGroupIdentifier = "group.com.sakura.clash"
    public static let speedNotify = "com.sakura.clash.network.traffic.speed"
    
    // Darwin Notification (最快，不需要 App 启动)
    func postDarwinNotification(_ name : String) {
        // 发送 Darwin 通知
        let notificationNameCString = name.cString(using: .utf8)!
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString),
            nil,
            nil,
            true
        )
    }
}


