//
//  DarwinNotificationListener.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/24.
//

import CoreFoundation
import Foundation


class DarwinNotificationListener {
    
    static let shared = DarwinNotificationListener()

    private var callbacks: [String: () -> Void] = [:]
    private let lock = NSLock()
   
    public static let appGroupIdentifier = "group.com.sakura.clash"
    public static let speedNotify = "com.sakura.clash.network.traffic.speed"
       
       // MARK: - 注册通知
       
       /// 注册通知监听
       /// - Parameters:
       ///   - notificationName: 通知名称 (e.g., "com.example.app.message")
       ///   - callback: 收到通知时的回调
       func register(_ notificationName: String, callback: @escaping () -> Void) {
           // 保存回调
           lock.lock()
           callbacks[notificationName] = callback
           lock.unlock()
           
           // 注册监听
           let observerPointer = Unmanaged.passUnretained(self).toOpaque()
           
           CFNotificationCenterAddObserver(
               CFNotificationCenterGetDarwinNotifyCenter(),
               observerPointer,
               { center, observer, name, object, userInfo in
                   guard let observer = observer else { return }
                   let manager = Unmanaged<DarwinNotificationListener>
                       .fromOpaque(observer)
                       .takeUnretainedValue()
                   
                   if let notificationName = name?.rawValue as String? {
                       DispatchQueue.main.async {
                           manager.lock.lock()
                           let callback = manager.callbacks[notificationName]
                           manager.lock.unlock()
                           callback?()
                       }
                   }
               },
               notificationName as CFString,
               nil,
               .deliverImmediately
           )
           
           print("✅ 已注册: \(notificationName)")
       }
       
       // MARK: - 取消注册
       
       /// 取消通知监听
       /// - Parameter notificationName: 通知名称
       func unregister(_ notificationName: String) {
           CFNotificationCenterRemoveObserver(
               CFNotificationCenterGetDarwinNotifyCenter(),
               Unmanaged.passUnretained(self).toOpaque(),
               CFNotificationName(notificationName as CFString),
               nil
           )
           
           lock.lock()
           callbacks.removeValue(forKey: notificationName)
           lock.unlock()
           
           print("❌ 已取消: \(notificationName)")
       }
}
