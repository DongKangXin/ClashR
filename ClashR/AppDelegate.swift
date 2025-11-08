//
//  AppDelegate.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/21.
//
import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let locationManager = LocationManager.shared

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        initializeAppGroupResources()
        
        return true
    }
    
    private func initializeAppGroupResources() {
        _ = FileUtils.copyFileFromBundle(fileName: "config.yaml", toSubpath: ClashManager.defaultFileName,force: false)
        _ = FileUtils.copyFileFromBundle(fileName: "reject.yaml", toSubpath: "rules/reject.yaml",force: false)
        _ = FileUtils.copyFileFromBundle(fileName: "geoip.metadb", toSubpath: "geoip.metadb",force: false)
    }
}
