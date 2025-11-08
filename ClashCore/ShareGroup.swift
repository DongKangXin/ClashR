//
//  ShareLocal.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/24.
//

import Foundation

private enum Key {
    static let proxyName     = "proxy.name"
    static let proxyMode     = "proxy.mode"
    static let uploadSpeed   = "net.upload.bps"    // 建议单位：字节/秒或比特/秒，统一约定
    static let downloadSpeed = "net.download.bps"
}

struct ShareGroup{
    static let sharedDefaults = UserDefaults(suiteName: "group.com.sakura.clash")!
    
    // MARK: - proxyName
    static func setProxyName(_ proxyName: String?) {
        sharedDefaults.set(proxyName, forKey: Key.proxyName)
    }

    static func getProxyName() -> String? {
        sharedDefaults.string(forKey: Key.proxyName)
    }

    // MARK: - proxyMode
    static func setProxyMode(_ mode: String?) {
        sharedDefaults.set(mode, forKey: Key.proxyMode)
    }

    static func getProxyMode() -> String? {
        sharedDefaults.string(forKey: Key.proxyMode)
    }

    // MARK: - uploadSpeed / downloadSpeed
    // 用 Int64 存储速率，避免大数溢出；单位自行约定（例如 bytesPerSecond）
    static func setUploadSpeed(_ bps: Int) {
        sharedDefaults.set(bps, forKey: Key.uploadSpeed)
    }

    static func getUploadSpeed() -> Int {
        // integer(forKey:) 只有 Int；这里用 object(forKey:) 取，再转 Int64
        sharedDefaults.integer(forKey: Key.uploadSpeed)
    }

    static func setDownloadSpeed(_ bps: Int) {
        sharedDefaults.set(bps, forKey: Key.downloadSpeed)
    }

    static func getDownloadSpeed() -> Int {
        sharedDefaults.integer(forKey: Key.downloadSpeed)
    }

}
