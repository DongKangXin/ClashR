//
//  SettingsView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI
internal import CoreLocation

/// 设置页面
struct SettingsView: View {
    @EnvironmentObject var clashService: ClashService
    @EnvironmentObject var vpnManager: VPNManager
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var clashActivityManager: ClashActivityManager
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                // 代理设置
                Section("代理设置") {
                    Toggle("开启灵动岛", isOn: Binding(
                        get: {return settings.enableLinkActivity},
                        set: {newValue in
                            if(newValue == false) {
                                settings.enableLinkActivity = false
                                clashActivityManager.endActivity()
                            }else{
                                clashActivityManager.checkLocationPermssion { status in
                                    if status == .authorizedAlways {
                                        clashActivityManager.startActivity()
                                        settings.enableLinkActivity = true
                                    } else {
                                        clashActivityManager.endActivity()
                                        settings.enableLinkActivity = false
                                    }
                                }
                            }
                           
                        }
                    ))
                    
                    HStack {
                        Text("当前模式")
                        Spacer()
                        Text(clashService.currentMode.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("代理状态")
                        Spacer()
                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(vpnManager.connect.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("关于 ClashR") {
                        showingAbout = true
                    }
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
    private var statusColor: Color {
        switch vpnManager.connect {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .disconnecting: return .orange
        }
    }
}

/// 关于页面
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 应用图标和名称
                    VStack(spacing: 16) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Clash")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("iOS Clash 客户端")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 版本信息
                    VStack(spacing: 8) {
                        Text("版本 1.0.0")
                            .font(.headline)
                        
                        Text("基于开源 Clash 内核")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 功能特性
                    VStack(alignment: .leading, spacing: 12) {
                        Text("主要功能")
                            .font(.headline)
                        
                        FeatureRow(icon: "shield.fill", title: "代理服务控制", description: "启动/停止代理服务")
                        FeatureRow(icon: "doc.text.fill", title: "配置管理", description: "导入和管理配置文件")
                        FeatureRow(icon: "link", title: "订阅功能", description: "支持订阅链接自动更新")
                        FeatureRow(icon: "network", title: "节点选择", description: "多节点管理和延迟测试")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 功能特性行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ClashService.share)
        .environmentObject(VPNManager.share)
}
