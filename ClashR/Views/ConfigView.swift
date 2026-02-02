//
//  ConfigView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI
import UniformTypeIdentifiers
import Yams

/// 配置管理页面
struct ConfigView: View {
    @EnvironmentObject var clashManager : ClashManager
    @EnvironmentObject var settings : Settings
    @State private var showingImportAlert = false
    @State private var configInput = ""
    @State private var showingEditConfig = false
    @State private var showingEditYAML = false // 新增：直接编辑 YAML 的入口状态
    
    var body: some View {
        NavigationStack {
            List {
                // 基础配置
                Section("基础配置") {
                    Toggle("允许局域网", isOn: $clashManager.allowLan)
                        .onSubmit {
                            _ = clashManager.saveToFile()
                        }
                    Toggle("IPV6", isOn: $clashManager.ipv6)
                        .onSubmit {
                            _ = clashManager.saveToFile()
                        }
//                    TextEditRow(
//                        title: "监听地址",
//                        value: clashManager.bindAddress,
//                        keyboardType: .decimalPad
//                    ) { newValue in
//                        clashManager.bindAddress = newValue
//                        _ = clashManager.saveToFile()
//                    }
//                    
//                    // ✅ 整数编辑
//                    IntEditRow(
//                        title: "混合端口",
//                        value: clashManager.mixedPort,
//                        range: 1...65535
//                    ) { newValue in
//                        clashManager.mixedPort = newValue
//                        _ = clashManager.saveToFile()
//                    }
//                    // ✅ 一行搞定：显示 + 跳转 + 保存
//                    SelectionEditRow(
//                        title: "代理模式",
//                        options: ["规则模式", "全局模式", "直连模式"],
//                        values: ["rule", "global", "direct"],
//                        currentValue: clashManager.mode,
//                        onSelection: { newValue in
//                            clashManager.mode = newValue
//                            _ = clashManager.saveToFile()
//                        }
//                    )
                    // ✅ 一行搞定：显示 + 跳转 + 保存
                    SelectionEditRow(
                        title: "日志等级",
                        options: ["调试", "信息", "警告", "错误"],
                        values: ["debug", "info", "warning","error"],
                        currentValue: settings.logLevel,
                        onSelection: { newValue in
                            settings.logLevel = newValue
                        }
                    )
//                    TextEditRow(
//                        title: "外部控制器",
//                        value: clashManager.externalController,
//                        keyboardType: .decimalPad
//                    ) { newValue in
//                        clashManager.externalController = newValue
//                        _ = clashManager.saveToFile()
//                    }
                }
                
                
                // DNS配置
                Section("DNS配置") {
//                    Toggle("启用DNS", isOn: Binding(
//                        get: { clashManager.getDNS().enable ?? true },
//                        set: { newValue in
//                            var dns = clashManager.getDNS()
//                            dns.enable = newValue
//                            clashManager.setDNS(dns)
//                            _ = clashManager.saveToFile()
//                        }
//                    ))
//                    Toggle("IPv6支持", isOn: Binding(
//                        get: { clashManager.getDNS().ipv6 ?? true },
//                        set: { newValue in
//                            var dns = clashManager.getDNS()
//                            dns.ipv6 = newValue
//                            clashManager.setDNS(dns)
//                            _ = clashManager.saveToFile()
//                        }
//                    ))
//                    TextEditRow(
//                        title: "默认DNS",
//                        value: clashManager.getDNS().defaultNameserver?.joined(separator: ", ") ?? "223.5.5.5, 119.29.29.29" ,
//                        keyboardType: .decimalPad
//                    ) { newValue in
//                        var dns = clashManager.getDNS()
//                        dns.defaultNameserver = newValue.components(separatedBy: ",")
//                            .map { $0.trimmingCharacters(in: .whitespaces) }
//                            .filter { !$0.isEmpty }
//                        clashManager.setDNS(dns)
//                        _ = clashManager.saveToFile()
//                    }
//                    TextEditRow(
//                        title: "Fake IP范围",
//                        value: clashManager.getDNS().fakeIpRange ?? "198.18.0.1/16" ,
//                        keyboardType: .decimalPad
//                    ) { newValue in
//                        var dns = clashManager.getDNS()
//                        dns.fakeIpRange = newValue
//                        clashManager.setDNS(dns)
//                        _ = clashManager.saveToFile()
//                    }
//                    Toggle("使用Hosts", isOn: Binding(
//                        get: { clashManager.getDNS().useHosts ?? true },
//                        set: { newValue in
//                            var dns = clashManager.getDNS()
//                            dns.useHosts = newValue
//                            clashManager.setDNS(dns)
//                            _ = clashManager.saveToFile()
//                        }
//                    ))
                    
                    
                }
                
            }
            .navigationTitle("配置管理")
            // 新增：YAML 编辑视图入口
            .sheet(isPresented: $showingEditYAML) {
                ConfigYAMLEditView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("编辑YAML") {
                            showingEditYAML = true
                        }
                        Button("恢复默认配置") {
                            do {
                                try clashManager.backDefault()
                            }catch{
                                
                            }
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}



// 查看 YAML 的视图
struct ConfigYAMLEditView: View {
    @EnvironmentObject var clashManager: ClashManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var rawYAML: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextEditor(text: $rawYAML)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )

                Text("保存将解析并校验 YAML，成功后实时写入到 config.yml")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("查看 YAML")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
            .onAppear {
                rawYAML = (try? clashManager.readConfigFile()) ?? ""
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}



#Preview {
    ConfigView()
        .environmentObject(ClashManager.share)
}
