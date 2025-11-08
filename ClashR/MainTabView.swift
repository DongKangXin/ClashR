//
//  MainTabView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI

/// 主标签页视图
struct MainTabView: View {
    
    @SceneStorage("selectedTab") private var selectedTab = 0
    @State var isScrolling = false


    var body: some View {
    
        if #available(iOS 26.0, *) {
            TabView(selection: $selectedTab) {
                // 首页
                Tab("主页", systemImage: "house.fill",value: 0) {
                    
                    HomeView()
                }
                
                // 配置页
                Tab("配置",systemImage: "slider.horizontal.3",value: 1){
                    ConfigView()
                }
                
                Tab("日志",systemImage: "doc.text",value: 2){
                    // 日志页
                    LogView()
                }
                //设置页
                Tab("设置",systemImage: "gear",value: 3){
                    SettingsView()
                }
                
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewStyle(.sidebarAdaptable)
        } else {
            TabView(selection: $selectedTab) {
                // 首页
                Tab("主页", systemImage: "house.fill",value: 0) {
                    
                    HomeView()
                }
                
                // 配置页
                Tab("配置",systemImage: "slider.horizontal.3",value: 1){
                    ConfigView()
                }
                
                Tab("日志",systemImage: "doc.text",value: 2){
                    // 日志页
                    LogView()
                }
                //设置页
                Tab("设置",systemImage: "gear",value: 3){
                    SettingsView()
                }
                
            }
            .tabViewStyle(.sidebarAdaptable)
        }
    }
}
