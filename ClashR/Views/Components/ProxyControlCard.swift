//
//  ProxyControlCard.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/22.
//
import Foundation
import SwiftUI
import SwiftData

/// 代理控制卡片（合并状态和模式）
struct ProxyControlCard: View {
    @EnvironmentObject var clashService: ClashService
    @EnvironmentObject var clashManager: ClashManager
    @EnvironmentObject var vpnManager: VPNManager
    @EnvironmentObject var clashApiService: ClashAPIService
    @EnvironmentObject var settings: Settings
    
    @Query(sort:\ClashProxy.createAt) private var proxys:[ClashProxy]
        

    var body: some View {
        Section{
            // 状态和控制区域
            HStack {
                // 图标（使用 SF Symbols）
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(maxWidth: 35)

                Text("代理状态")
                    .font(.headline)
                    .foregroundColor(.primary)
                // 💬 文字状态提示（模仿设置 App）
                Text(vpnManager.connect.displayName)
                    .font(.caption)
                    .foregroundStyle(vpnManager.connect.color)
                    .animation(.default, value: vpnManager.connect) // 平滑过渡
                Spacer()
                // 🔁 始终显示 Toggle —— 这是原生的关键！
                Toggle(
                    isOn: Binding(
                        get: { vpnManager.connect != .disconnected },
                        set: { newValue in
                            Task {
                                if newValue && vpnManager.connect == .disconnected {
                                    try await vpnManager.startNETunnel()
                                } else if !newValue && vpnManager.connect == .connected {
                                    try await vpnManager.stopNETunnel()
                                }
                            }
                        }
                    )
                ) {
                    // Label hidden because we already have text
                }
                .labelsHidden()
                .disabled(vpnManager.connect == .connecting || vpnManager.connect == .disconnecting) // 禁用期间防止重复点击
                
            }

            // 模式选择区域
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(maxWidth: 35)

                Text("代理模式")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()

                Picker("代理模式", selection: $settings.proxyMode) {
                    Text("直连").tag(ProxyMode.direct)
                    Text("全局").tag(ProxyMode.global)
                    Text("规则").tag(ProxyMode.rule)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 200)
            }
            
            HStack{
                Image(systemName: "switch.2")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(maxWidth: 35)
                Text("代理选择")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                Picker("代理选择", selection: Binding(
                    get:{settings.autoProxy},
                    set:{_ in withAnimation{settings.autoProxy.toggle()}}
                ) ){
                    Text("自动").tag(true)
                    Text("手动").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: 200)
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

    private var buttonTitle: String {
        switch vpnManager.connect {
        case .disconnected: return "连接"
        case .connecting: return "连接中..."
        case .connected: return "断开"
        case .disconnecting: return "断开中..."
        }
    }

    private var buttonIcon: String {
        switch vpnManager.connect {
        case .disconnected: return "play.fill"
        case .connecting: return "hourglass"
        case .connected: return "stop.fill"
        case .disconnecting: return "hourglass"
        }
    }

    private var buttonColor: Color {
        switch vpnManager.connect {
        case .disconnected: return .blue
        case .connecting: return .orange
        case .connected: return .red
        case .disconnecting: return .orange
        }
    }
}

struct ClashStatusCard: View {
    @EnvironmentObject var vpnManager: VPNManager
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题行
            HStack(spacing: 12) {
                Text("代理状态")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 💬 文字状态提示（模仿设置 App）
                Text(vpnManager.connect.displayName)
                    .font(.caption)
                    .foregroundStyle(vpnManager.connect.color)
                    .animation(.default, value: vpnManager.connect) // 平滑过渡
            }
            
            
            // 内容区
            if vpnManager.connect == .connected {
                VStack(spacing: 10) {
                    SpeedRow(label: "下载", speed: formatSpeed(vpnManager.downSpeed))
                    SpeedRow(label: "上传", speed: formatSpeed(vpnManager.uploadSpeed))
                }
            } else {
                Text("代理\(vpnManager.connect.displayName.lowercased())，点击下方按钮启用")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Divider()
            
            // ✅ 按钮组（系统风格）
            HStack(spacing: 12) {
                // 主操作：Bordered Prominent
                Button(action: { toggleVPN() }) {
                    Text(vpnManager.connect == .connected ? "断开连接" : "立即连接")
                        .font(.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(vpnManager.connect == .connected ? .red : .green)
               
            }
        }
    }
    
    private func toggleVPN() {
        Task {
            switch vpnManager.connect {
            case .connected:
                try await vpnManager.stopNETunnel()
            case .disconnected:
                try await vpnManager.startNETunnel()
            default:
                break
            }
        }
    }
    
    private func formatSpeed(_ bytesPerSecond: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
    }
}

struct SpeedRow: View {
    let label: String
    let speed: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            Spacer()
            
            Text(speed)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .monospacedDigit()
        }
    }
}

#Preview {
    List {
        ClashStatusCard()
            .environmentObject(VPNManager())
    }
    .listStyle(.insetGrouped)
}
