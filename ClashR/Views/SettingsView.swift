//
//  SettingsView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI

/// 设置页面
struct SettingsView: View {
    @EnvironmentObject var clashService: ClashService
    @AppStorage("autoConnect") private var autoConnect = false
    @AppStorage("darkMode") private var darkMode = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                // 代理设置
                Section("代理设置") {
                    Toggle("启动时自动连接", isOn: $autoConnect)
                        .onChange(of: autoConnect) { _ in
                            // 保存设置
                        }
                    
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
                            Text(clashService.proxyStatus.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 界面设置
                Section("界面设置") {
                    Toggle("深色模式", isOn: $darkMode)
                        .onChange(of: darkMode) { _ in
                            // 切换深色模式
                        }
                }
                
                // 流量统计
                Section("流量统计") {
                    HStack {
                        Text("今日上传")
                        Spacer()
                        Text(clashService.trafficStats.formatBytes(clashService.trafficStats.todayUploadBytes))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("今日下载")
                        Spacer()
                        Text(clashService.trafficStats.formatBytes(clashService.trafficStats.todayDownloadBytes))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("总上传")
                        Spacer()
                        Text(clashService.trafficStats.formatBytes(clashService.trafficStats.uploadBytes))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("总下载")
                        Spacer()
                        Text(clashService.trafficStats.formatBytes(clashService.trafficStats.downloadBytes))
                            .foregroundColor(.secondary)
                    }
                    
                    Button("清空今日流量") {
                        clashService.clearTodayTraffic()
                    }
                    .foregroundColor(.red)
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
                    
                    Button("GitHub 项目") {
                        if let url = URL(string: "https://github.com/your-username/ClashR") {
                            UIApplication.shared.open(url)
                        }
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
        switch clashService.proxyStatus {
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
                        
                        Text("ClashR")
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
                        FeatureRow(icon: "chart.bar.fill", title: "流量监控", description: "实时流量统计和监控")
                        FeatureRow(icon: "doc.text.magnifyingglass", title: "日志查看", description: "实时日志输出和过滤")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 开源声明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("开源声明")
                            .font(.headline)
                        
                        Text("本项目基于开源 Clash 内核开发，遵循开源协议。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("项目地址: https://github.com/your-username/ClashR")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                if let url = URL(string: "https://github.com/your-username/ClashR") {
                                    UIApplication.shared.open(url)
                                }
                            }
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
        .environmentObject(ClashService())
}
