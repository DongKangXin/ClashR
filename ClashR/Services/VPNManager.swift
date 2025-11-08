//
//  VPN.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/5.
//

import Foundation
import Combine
import NetworkExtension
internal import CoreLocation

/// VPN操作服务类
@MainActor
class VPNManager: ObservableObject {
    
    static let share = VPNManager()
    
    @Published var connect: ProxyStatus = .disconnected
    @Published var uploadSpeed: Int = 0
    @Published var downSpeed: Int = 0
    
    lazy var settings = Settings.shared
    
    lazy var clashManager = ClashManager.share
    lazy var clashService = ClashService.share
    lazy var clashApiService = ClashAPIService.shared
    lazy var clashActivityManager = ClashActivityManager.shared

    
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.sakura.clash")!

    
    // MARK: - NETunnelProvider 集成与 IPC
    open var tunnelManager: NETunnelProviderManager?
    
    /// 确保隧道管理器已初始化
    private func ensureTunnelManager() async throws {
        // Step 1: 如果已经在内存中，直接返回
        var newManager : NETunnelProviderManager
        if let exist = tunnelManager {
            newManager = exist
        } else {
            // Step 2: 从系统偏好中加载所有已保存的隧道管理器
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()

            // Step 3: 查找我们自己的那个（通过 bundleId）
            if let savedManager = managers.first(where: { manager in
                guard let proto = manager.protocolConfiguration as? NETunnelProviderProtocol else { return false }
                return proto.providerBundleIdentifier == "com.sakura.clash.clash-tunnel"
            }) {
                // 找到了！使用它
                newManager = savedManager
                print("✅ 找到已存在的隧道管理器")
            } else {
                // Step 4: 没找到，创建新的
                newManager = NETunnelProviderManager()
                print("🆕 创建新的隧道管理器")
            }
        }

        // 配置隧道协议
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "com.sakura.clash.clash-tunnel"
        proto.serverAddress = "ClashR"

        newManager.protocolConfiguration = proto
        newManager.localizedDescription = "ClashR Packet Tunnel"
        newManager.isEnabled = true

        // 保存到系统设置
        try await newManager.saveToPreferences()
        print("💾 隧道配置已保存到系统偏好设置")

        // 再次 load，确保状态同步（关键！）
        try await newManager.loadFromPreferences()
        print("🔄 隧道管理器状态已同步")

        tunnelManager = newManager
    }

    /// 启动代理服务
    func startNETunnel() async throws {
        do {
            self.connect = .connecting
            clashService.addLog(level: .info, message: "正在启动代理服务...")
            
            try await ensureTunnelManager()
            try await configClash()
            guard let manager = tunnelManager else {
                throw NSError(domain: "ClashR", code: -2, userInfo: [NSLocalizedDescriptionKey: "TunnelManager 未初始化"])
            }
            try await manager.connection.stopVPNTunnel()
            try await manager.connection.startVPNTunnel()
            
            pollUntil(
                getValue: { self.tunnelManager?.connection.status },
                targetValue: .connected,
                onMatch: {
                    print("✅ 连接成功！")
                    self.connect = .connected
                    self.clashApiService.startLogStreaming()
                    if self.settings.enableLinkActivity {
                        self.clashActivityManager.startActivity()
                    }
                },
                onTimeout: {
                    print("❌ 超时未连接")
                    self.connect = .disconnected
                }
            )
            
        } catch {
            self.connect = .disconnected
            clashService.addLog(level: .error, message: "代理服务启动失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    func configClash(){
        clashManager.loadFromDefault()
        clashManager.setMode(settings.proxyMode.rawValue)
        clashManager.setLogLevel(settings.logLevel)
        clashManager.setProxies(settings.proxyNodes)
        clashManager.setAutoProxyNames(settings.proxyNodes.map(\.name))
        
        // 单点模式
        if(!settings.autoProxy && settings.selectProxy != nil){
            clashManager.setUserProxieName(settings.selectProxy!)
        }else{
            clashManager.setUserProxieName("AUTO")
        }
        clashManager.saveToFile()
    }

    /// 停止代理服务
    func stopNETunnel() async throws {
        
        clashActivityManager.endActivity()
        self.clashApiService.stopLogStream()
        guard let manager = tunnelManager else {
            clashService.addLog(level: .warning, message: "隧道管理器不存在，无需停止")
            return
        }

        await manager.connection.stopVPNTunnel()
        self.connect = .disconnected
        clashService.addLog(level: .info, message: "代理服务关闭成功")
    }

    /// 获取隧道连接状态
    func getTunnelStatus() -> NEVPNStatus {
        return tunnelManager?.connection.status ?? .invalid
    }
    
}
