//
//  ClashBridge.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/5.
//

import Foundation
import Combine
import NetworkExtension
import Mihomo
import ClashCore
import SwiftUI


/// Clash核心服务类
class ClashBridge: ObservableObject {
    
    private var tunnelManager: NETunnelProviderManager?
    private let userDefaults = UserDefaults.standard
    
    @AppStorage("pid") var pid : Int?
    init() {
        
    }
    
    ///启动clash内核
    func startClash() {
        guard let homePath = FileUtils.absolutePath(forSubpath: "") else {
            print("❌ 无法Home路径，Clash 启动失败")
            return
        }
        guard let configPath = FileUtils.absolutePath(forSubpath: "config.yaml") else {
            print("❌ 无法获取配置路径，Clash 启动失败")
            return
        }

        // 启动 Clash
        MihomoStartClash(homePath, configPath)
        print("[\(Date().formatted(.iso8601))] ✅ Clash 内核启动成功")
    }

    ///关闭clash内核
    func stopClash() {
        print("🛑 停止 Clash 内核")
        MihomoStopClash()
    }

    ///重启clash内核
    func reloadClash() {
        print("🔄 重启 Clash 内核")
        stopClash()
        startClash()
    }

    // 杀掉上次的核心（进程组优先）
    func killStaleCore(timeout: TimeInterval = 2.0) {
        let pid: Int32 = 9999
        // 先优雅后强制
        kill(-pid, SIGTERM)  // 负号=发给进程组
        let deadline = Date().addingTimeInterval(timeout)
        var dead = false
        while Date() < deadline {
            if kill(pid, 0) != 0 { // 进程不存在
                dead = true
                break
            }
            usleep(50_000)
        }
        if !dead {
            kill(-pid, SIGKILL)
        }
        // 这里不一定能 waitpid（若不是当前父进程），但 kill 返回即可
    }
}
