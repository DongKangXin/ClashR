//
//  ClashApp.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI
import SwiftData
import ActivityKit

@main
struct ClashApp: App {


    // 绑定初始化 AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = Settings.shared
    @StateObject private var clashService = ClashService.share
    @StateObject private var clashManager = ClashManager.share
    @StateObject private var vpnManager = VPNManager.share
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var clashApiService = ClashAPIService.shared
    @StateObject private var clashActivityManager = ClashActivityManager.shared
    
    private let modelContainer: ModelContainer
    init() {
        _settings = StateObject(wrappedValue: Settings.shared)
        
        do {
            modelContainer = try ModelContainer(
                for: Subscription.self, ClashProxy.self
            )
        } catch {
            fatalError("❌ ModelContainer 初始化失败: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(modelContainer)
                .onAppear {
                    settings.setModelContext(modelContainer.mainContext)
                }
                .environmentObject(clashService)
                .environmentObject(clashManager)
                .environmentObject(vpnManager)
                .environmentObject(subscriptionManager)
                .environmentObject(clashApiService)
                .environmentObject(settings)
                .environmentObject(clashActivityManager)
        }
        .modelContainer(for: [Subscription.self, ClashProxy.self])
    }
    
}
