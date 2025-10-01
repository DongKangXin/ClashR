//
//  MainTabView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI

/// 主标签页视图
struct MainTabView: View {
    @StateObject private var clashService = ClashService()
    @StateObject private var configManager = ConfigManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    var body: some View {
        TabView {
            // 首页
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .environmentObject(clashService)
                .environmentObject(configManager)
            
            // 配置页
            ConfigView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("配置")
                }
                .environmentObject(configManager)
            
            // 订阅页
            SubscriptionView()
                .tabItem {
                    Image(systemName: "link")
                    Text("订阅")
                }
                .environmentObject(subscriptionManager)
            
            // 节点页
            ProxyView()
                .tabItem {
                    Image(systemName: "network")
                    Text("节点")
                }
                .environmentObject(clashService)
            
            // 日志页
            LogView()
                .tabItem {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("日志")
                }
                .environmentObject(clashService)
            
            // 设置页
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .environmentObject(clashService)
        }
        .accentColor(.blue)
    }
}
