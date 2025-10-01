//
//  ConfigView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI
import UniformTypeIdentifiers

/// 配置管理页面
struct ConfigView: View {
    @EnvironmentObject var configManager: ConfigManager
    @State private var showingFileImporter = false
    @State private var showingAddConfig = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(configManager.configs) { config in
                    ConfigDetailRowView(config: config)
                        .environmentObject(configManager)
                }
                .onDelete(perform: deleteConfigs)
            }
            .navigationTitle("配置管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingFileImporter = true
                        }) {
                            Label("导入配置文件", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: {
                            showingAddConfig = true
                        }) {
                            Label("添加配置", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [UTType.yaml, UTType.text],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showingAddConfig) {
                AddConfigView()
                    .environmentObject(configManager)
            }
        }
    }
    
    private func deleteConfigs(offsets: IndexSet) {
        for index in offsets {
            let config = configManager.configs[index]
            try? configManager.deleteConfig(config)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // 获取文件名作为配置名称
            let configName = url.lastPathComponent.replacingOccurrences(of: ".yaml", with: "")
            
            do {
                _ = try configManager.importConfig(from: url, name: configName)
            } catch {
                print("导入配置失败: \(error)")
            }
            
        case .failure(let error):
            print("文件选择失败: \(error)")
        }
    }
}

/// 配置详情行视图
struct ConfigDetailRowView: View {
    let config: ClashConfig
    @EnvironmentObject var configManager: ConfigManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(config.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
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
            }
            
            Text("创建时间: \(config.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("更新时间: \(config.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("设为默认") {
                    configManager.setDefaultConfig(config)
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button("删除") {
                    showingDeleteAlert = true
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .alert("删除配置", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                try? configManager.deleteConfig(config)
            }
        } message: {
            Text("确定要删除配置 \"\(config.name)\" 吗？此操作不可撤销。")
        }
    }
}

/// 添加配置视图
struct AddConfigView: View {
    @EnvironmentObject var configManager: ConfigManager
    @Environment(\.dismiss) private var dismiss
    @State private var configName = ""
    @State private var yamlContent = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("配置信息") {
                    TextField("配置名称", text: $configName)
                }
                
                Section("YAML配置") {
                    TextEditor(text: $yamlContent)
                        .frame(minHeight: 300)
                }
            }
            .navigationTitle("添加配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveConfig()
                    }
                    .disabled(configName.isEmpty || yamlContent.isEmpty)
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveConfig() {
        do {
            _ = try configManager.addSubscriptionConfig(name: configName, yamlContent: yamlContent)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    ConfigView()
        .environmentObject(ConfigManager())
}
