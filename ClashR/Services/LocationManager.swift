//
//  LocationManager.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/24.

// LocationManager.swift
internal import CoreLocation
import Foundation
import UIKit

final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private let appGroup = "group.com.sakura.clash"
    private lazy var clashActivityManager = ClashActivityManager.shared
    private lazy var clashApiService = ClashAPIService.shared
    private var permissionCompletion: ((CLAuthorizationStatus) -> Void)?
    private var accuracyCompletion: ((CLAccuracyAuthorization) -> Void)?
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - 初始化定位管理器
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer  // 低精度节省电量
        locationManager.distanceFilter =  100 // 任何位置变化都触发
        locationManager.allowsBackgroundLocationUpdates = true  // ✅ 允许后台更新
        locationManager.pausesLocationUpdatesAutomatically = false  // ✅ 不自动暂停
        
        print("✅ 定位管理器已初始化")
    }
    
    /// ✅ 请求后台定位权限（始终允许）
    func requestAlwaysAuthorization(completion: @escaping (CLAuthorizationStatus) -> Void) {
        self.permissionCompletion = completion
        
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            
        case .authorizedWhenInUse:
            // 从前台升级到后台
            locationManager.requestAlwaysAuthorization()
            
        case .restricted, .denied:
            showPermissionAlert(type: .always)
            completion(status)
            
        case .authorizedAlways:
            completion(status)
            
        @unknown default:
            showPermissionAlert(type: .always)
            completion(status)
        }
    }
    
    // MARK: - 开始位置更新
    
    public func startLocationUpdates() {
//        locationManager.startMonitoringSignificantLocationChanges()
//        let region = CLCircularRegion(
//            center: CLLocationCoordinate2D(latitude: 39.9, longitude: 116.4),
//            radius: 1000,
//            identifier: UUID().uuidString
//        )
//        region.notifyOnEntry = true
//        region.notifyOnExit = true
//        locationManager.startMonitoring(for: region)
        locationManager.startUpdatingLocation()
//        locationManager.startUpdatingHeading()
    }
    
    public func stopLocationUpdates(){
//        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingLocation()
//        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - CLLocationManagerDelegate 回调
    
    
    // ✅ 进入/离开地理围栏回调（极省电）
    func locationManager(_ manager: CLLocationManager,
                       didEnterRegion region: CLRegion) {
        print("📍 收到位置更新")
        self.clashApiService.logs.append(ClashLogEntry(type: "error", payload: "通过定位更新"))
        clashActivityManager.sendSpeedToActivity()
    }
    
    func locationManager(_ manager: CLLocationManager,
                       didExitRegion region: CLRegion) {
        print("📍 收到位置更新")
        self.clashApiService.addLog(level: "debug", message:"通过定位更新")
        clashActivityManager.sendSpeedToActivity()
    }
    
    /// 位置更新时触发（即使 App 在后台也会调用）
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📍 收到位置更新")
        self.clashApiService.addLog(level: "debug", message:"通过定位更新")
        clashActivityManager.sendSpeedToActivity()
    }
    /// 位置更新时触发（即使 App 在后台也会调用）
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("📍 收到位置更新")
        self.clashApiService.addLog(level: "debug", message: "通过定位头更新")

        clashActivityManager.sendSpeedToActivity()
    }
    
    // MARK: - 私有方法
        
    private enum PermissionType {
        case whenInUse
        case always
    }
    
    private func showPermissionAlert(type: PermissionType) {
        let title = type == .whenInUse ? "位置权限被拒绝" : "后台位置权限被拒绝"
        let message = "请至设置页面为应用添加位置权限"
        
        GlobalAlertManager.shared.showAlert(
            title: title,
            message: message,
            actions: [
                UIAlertAction(title: "取消", style: .cancel),
                UIAlertAction(title: "去设置", style: .default) { _ in
                    self.openSettings()
                }
            ]
        )
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

}

