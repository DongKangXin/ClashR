//
//  ClashActivityManager.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/23.
//


import ActivityKit
import SwiftUI
import Combine
internal import CoreLocation


class ClashActivityManager : ObservableObject{
    static let shared = ClashActivityManager()
    
    private lazy var clashCore = ClashCore.share
    private lazy var darwinListener = DarwinNotificationListener.shared
    private lazy var clashApiService = ClashAPIService.shared
    private lazy var settings = Settings.shared
    private lazy var locationManager = LocationManager.shared
    
    private var activity: Activity<ClashActivityAttributes>?
        
    private var activityTimer: Timer?
    private var speedHistory: ChartData = ChartData()
    
    func checkLocationPermssion(_ completion: @escaping (CLAuthorizationStatus) -> Void) {
        return locationManager.requestAlwaysAuthorization(completion: completion )
    }
    
    
    // MARK: - 启动灵动岛
    func startActivity() {
        Task{
            // 清除旧的
            await clearAllActivities()
            checkLocationPermssion { status in
                if status == .authorizedAlways {
                    self.startNetworkActivity()
                } else {
                    self.settings.enableLinkActivity = false
                }
            }
            
        }
    }
    
    private func startNetworkActivity(){
        let attributes = ClashActivityAttributes(clashVersion: "1.0")
        let contentState = ActivityContent(state: getUpdateAttributes(), staleDate: nil)
        
        do {
            activity = try Activity<ClashActivityAttributes>.request(
                attributes: attributes,
                content: contentState
            )
            print("✅ 灵动岛已启动")
            addSpeedListener()
            print("✅ 灵动岛监听器已启动")
            self.locationManager.startLocationUpdates()
            print("📍 位置信息后台刷新已启动")
        } catch {
            print("❌ 启动灵动岛失败: \(error)")
        }
    }
    
    
    // MARK: - 结束灵动岛
    func endActivity() {
        self.locationManager.stopLocationUpdates()
        print("📍 位置信息后台刷新关闭")
        removeSpeedListener()
        print("✅ 灵动岛监听器已关闭")
        Task{
            await clearAllActivities()
            print("✅ 灵动岛已关闭")
        }
    }
    
    
    private func addSpeedListener(){
        darwinListener.register(DarwinNotificationListener.speedNotify,
                                callback:{
            self.sendSpeedToActivity()
            self.clashApiService.addLog(level: "debug", message: "通过消息更新网速")
        })
    }
    
    private func removeSpeedListener(){
        darwinListener.unregister(DarwinNotificationListener.speedNotify)
    }
    
    public func sendSpeedToActivity(){
        Task {
            await self.activity?.update(using: getUpdateAttributes())
        }
    }
    
    private func getUpdateAttributes() -> ClashActivityAttributes.ContentState{
        let upload = ShareGroup.getUploadSpeed()
        let download = ShareGroup.getDownloadSpeed()
        self.speedHistory.addPoint(Double(upload + upload))
        let showDownload = upload <= download
        let proxyName = self.settings.autoProxy ? "AUTO" : self.settings.selectProxy ?? "AUTO"
        let proxyMode = self.settings.proxyMode.displayName
        let uploadSpeed = self.formatSpeed(upload)
        let downloadSpeed = self.formatSpeed(download)
        return  ClashActivityAttributes.ContentState(
            showDownload: showDownload,
            proxyName: proxyName,
            proxyMode: proxyMode,
            downloadSpeed: downloadSpeed,
            uploadSpeed: uploadSpeed,
            latency: "-",
            time: formatTime(Date()),
            speedHistory: self.speedHistory
        )
    }
    
    private func formatTime(_ time : Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: time)
    }
    
    private func formatSpeed(_ bytesPerSecond: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB] // 不显示 Bytes
        formatter.countStyle = .binary // 1024 进制
        formatter.allowsNonnumericFormatting = false // 避免 "Zero KB"
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
    
    // 清除所有已存在的Activity
    func clearAllActivities() async{
        for activity in Activity<ClashActivityAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
    }
}


