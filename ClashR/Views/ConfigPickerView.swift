//
//  ConfigPickerView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI

/// 配置选择器视图
struct ConfigPickerView: View {
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var clashService: ClashService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(configManager.configs) { config in
                    ConfigRowView(config: config)
                        .environmentObject(configManager)
                        .environmentObject(clashService)
                }
            }
            .navigationTitle("选择配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 配置行视图
struct ConfigRowView: View {
    let config: ClashConfig
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var clashService: ClashService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(config.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("创建于 \(config.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if config.isDefault {
                Text("默认")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
            
            if clashService.currentConfig?.id == config.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                await clashService.switchConfig(to: config)
                dismiss()
            }
        }
    }
}

#Preview {
    ConfigPickerView()
        .environmentObject(ConfigManager())
        .environmentObject(ClashService())
}
