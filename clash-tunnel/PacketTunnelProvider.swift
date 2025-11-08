//
//  PacketTunnelProvider.swift
//  clash-tunnel
//
//  Created by 董康鑫 on 2025/10/3.
//

import NetworkExtension
import Tun2SocksKit
import UIKit
import SwiftUI

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private lazy var clashBridge = ClashBridge()
    private lazy var clashCore = ClashCore.share
        
    override func startTunnel(options: [String : NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        //清除已启动的clash
//        clashBridge.stopClash()
        // 1) 配置 utun，导入全局路由
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "240.0.0.1")
        settings.mtu = 1500

        // IPv4
        let ipv4 = NEIPv4Settings(addresses: ["240.0.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        ipv4.excludedRoutes = [
        NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
        NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
        NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0")
        ]
        settings.ipv4Settings = ipv4

        // 可选：IPv6（你的网络支持时再开启）
        // let ipv6 = NEIPv6Settings(addresses: ["fd00::1"], networkPrefixLengths: [64])
        // ipv6.includedRoutes = [NEIPv6Route.default()]
        // settings.ipv6Settings = ipv6

        // DNS：简单起步用公共 DNS，让查询也进 TUN
        settings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8","1.1.1.1"])

        // 全局代理不依赖系统 HTTP 代理
        // settings.proxySettings = nil

        setTunnelNetworkSettings(settings) { [weak self] err in
            guard let self = self, err == nil else { completionHandler(err); return }

            // 2) 启动 Clash（确保 socks 监听 127.0.0.1:7891 且支持 UDP）
            clashBridge.startClash()

            // 3) 组织 Tun2SocksKit 的配置（指向本机 SOCKS）
            // 如果 Clash 只监听 IPv4，请用 127.0.0.1；若监听 IPv6 回环可用 ::1
            let config = """
            tunnel:
                mtu: 1500
            socks5:
                address: 127.0.0.1
                port: 7891
                udp: udp
            misc:
                log-file: stderr
                log-level: error
            """

            // 4) 启动 Tun2SocksKit（非阻塞）
            Socks5Tunnel.run(withConfig: .string(content: config)) { code in
                // 正常运行不会立刻回调；若意外退出，可视情况重启或结束隧道
                if code != 0 {
                    // self.cancelTunnelWithError(NSError(domain: "Tun2Socks", code: Int(code), userInfo: nil))
                }
            }
            clashCore.startTrafficMonitoring()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // 5) 停止 Tun2SocksKit（根据版本可能是 quit() 或 stop()，有则调用）
        // 如果当前包没有暴露停止方法，扩展结束时进程会被系统终止，也能释放
        Socks5Tunnel.quit()
        clashBridge.stopClash()
        clashCore.stopTrafficMonitoring()
        completionHandler()
    }
    

}
