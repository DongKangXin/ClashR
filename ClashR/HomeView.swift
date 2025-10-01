//
//  HomeView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI

/// 首页Dashboard视图
struct HomeView: View {
    @EnvironmentObject var clashService: ClashService
    @EnvironmentObject var configManager: ConfigManager
    @State private var showingConfigPicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 状态卡片
                    StatusCard()
                        .environmentObject(clashService)
                    
                    // 流量统计卡片
                    TrafficCard()
                        .environmentObject(clashService)
                    
                    // 模式切换卡片
                    ModeCard()
                        .environmentObject(clashService)
                    
                    // 快捷操作按钮
                    QuickActionsCard()
                        .environmentObject(clashService)
                        .environmentObject(configManager)
                    
                    // 当前配置信息
                    CurrentConfigCard()
                        .environmentObject(clashService)
                        .environmentObject(configManager)
                }
                .padding()
            }
            .navigationTitle("ClashR")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }
}

/// 状态卡片
struct StatusCard: View {
    @EnvironmentObject var clashService: ClashService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("代理状态")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(clashService.proxyStatus.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 状态指示器
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .scaleEffect(clashService.proxyStatus == .connecting || clashService.proxyStatus == .disconnecting ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), 
                              value: clashService.proxyStatus == .connecting || clashService.proxyStatus == .disconnecting)
            }
            
            // 连接/断开按钮
            Button(action: {
                Task {
                    if clashService.proxyStatus == .connected {
                        await clashService.stopProxy()
                    } else {
                        await clashService.startProxy()
                    }
                }
            }) {
                HStack {
                    Image(systemName: buttonIcon)
                    Text(buttonTitle)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(buttonColor)
                .cornerRadius(12)
            }
            .disabled(clashService.proxyStatus == .connecting || clashService.proxyStatus == .disconnecting)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch clashService.proxyStatus {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .disconnecting: return .orange
        }
    }
    
    private var buttonTitle: String {
        switch clashService.proxyStatus {
        case .disconnected: return "连接"
        case .connecting: return "连接中..."
        case .connected: return "断开"
        case .disconnecting: return "断开中..."
        }
    }
    
    private var buttonIcon: String {
        switch clashService.proxyStatus {
        case .disconnected: return "play.fill"
        case .connecting: return "hourglass"
        case .connected: return "stop.fill"
        case .disconnecting: return "hourglass"
        }
    }
    
    private var buttonColor: Color {
        switch clashService.proxyStatus {
        case .disconnected: return .blue
        case .connecting: return .orange
        case .connected: return .red
        case .disconnecting: return .orange
        }
    }
}

/// 流量统计卡片
struct TrafficCard: View {
    @EnvironmentObject var clashService: ClashService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("流量统计")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("清空") {
                    clashService.clearTodayTraffic()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // 实时速度
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("上传")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(clashService.trafficStats.formatSpeed(clashService.trafficStats.uploadSpeed))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text("下载")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(clashService.trafficStats.formatSpeed(clashService.trafficStats.downloadSpeed))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            Divider()
            
            // 今日流量
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("今日上传")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(clashService.trafficStats.formatBytes(clashService.trafficStats.todayUploadBytes))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text("今日下载")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(clashService.trafficStats.formatBytes(clashService.trafficStats.todayDownloadBytes))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// 模式切换卡片
struct ModeCard: View {
    @EnvironmentObject var clashService: ClashService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("代理模式")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(ProxyMode.allCases, id: \.self) { mode in
                    Button(action: {
                        Task {
                            await clashService.switchMode(to: mode)
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                            
                            Text(mode.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(clashService.currentMode == mode ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(clashService.currentMode == mode ? Color.blue : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .disabled(clashService.proxyStatus != .connected)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// 快捷操作卡片
struct QuickActionsCard: View {
    @EnvironmentObject var clashService: ClashService
    @EnvironmentObject var configManager: ConfigManager
    @State private var showingConfigPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("快捷操作")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // 切换配置按钮
                Button(action: {
                    showingConfigPicker = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.title3)
                        
                        Text("切换配置")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // 测试延迟按钮
                Button(action: {
                    if let selectedNode = clashService.proxyNodes.first(where: { $0.isSelected }) {
                        Task {
                            await clashService.testNodeLatency(selectedNode)
                        }
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "speedometer")
                            .font(.title3)
                        
                        Text("测试延迟")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .disabled(clashService.proxyNodes.isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingConfigPicker) {
            ConfigPickerView()
                .environmentObject(configManager)
                .environmentObject(clashService)
        }
    }
}

/// 当前配置信息卡片
struct CurrentConfigCard: View {
    @EnvironmentObject var clashService: ClashService
    @EnvironmentObject var configManager: ConfigManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("当前配置")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            if let config = clashService.currentConfig {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("配置名称:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(config.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("创建时间:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(config.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("节点数量:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(clashService.proxyNodes.count)")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            } else {
                Text("暂无配置")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
        .environmentObject(ClashService())
        .environmentObject(ConfigManager())
}
