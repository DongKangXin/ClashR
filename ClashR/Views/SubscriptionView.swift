//
//  SubscriptionView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI

/// 订阅管理页面
struct SubscriptionView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingAddSubscription = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(subscriptionManager.subscriptions) { subscription in
                    SubscriptionRowView(subscription: subscription)
                        .environmentObject(subscriptionManager)
                }
                .onDelete(perform: deleteSubscriptions)
            }
            .navigationTitle("订阅管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await subscriptionManager.updateAllSubscriptions()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSubscription = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView()
                    .environmentObject(subscriptionManager)
            }
            .refreshable {
                await subscriptionManager.updateAllSubscriptions()
            }
        }
    }
    
    private func deleteSubscriptions(offsets: IndexSet) {
        for index in offsets {
            let subscription = subscriptionManager.subscriptions[index]
            subscriptionManager.deleteSubscription(subscription)
        }
    }
}

/// 订阅行视图
struct SubscriptionRowView: View {
    let subscription: Subscription
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isUpdating = false
    
    // 获取当前订阅的可变引用
    private var currentSubscription: Subscription? {
        subscriptionManager.subscriptions.first { $0.id == subscription.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { currentSubscription?.isEnabled ?? false },
                    set: { _ in subscriptionManager.toggleSubscription(subscription) }
                ))
                .labelsHidden()
            }
            
            Text(subscription.url)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                if let lastUpdate = currentSubscription?.lastUpdate {
                    Text("最后更新: \(lastUpdate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("从未更新")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        isUpdating = true
                        await subscriptionManager.updateSubscription(subscription)
                        isUpdating = false
                    }
                }) {
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isUpdating || !(currentSubscription?.isEnabled ?? false))
                .foregroundColor(.blue)
            }
            
            if currentSubscription?.autoUpdate == true {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("自动更新: 每\(formatUpdateInterval(currentSubscription?.updateInterval ?? 0))")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatUpdateInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        if hours < 24 {
            return "\(hours)小时"
        } else {
            let days = hours / 24
            return "\(days)天"
        }
    }
}

/// 添加订阅视图
struct AddSubscriptionView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var subscriptionName = ""
    @State private var subscriptionURL = ""
    @State private var autoUpdate = false
    @State private var updateInterval: TimeInterval = 6 * 60 * 60 // 6小时
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("订阅信息") {
                    TextField("订阅名称", text: $subscriptionName)
                    TextField("订阅链接", text: $subscriptionURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("自动更新") {
                    Toggle("启用自动更新", isOn: $autoUpdate)
                    
                    if autoUpdate {
                        Picker("更新间隔", selection: $updateInterval) {
                            Text("1小时").tag(1 * 60 * 60.0)
                            Text("3小时").tag(3 * 60 * 60.0)
                            Text("6小时").tag(6 * 60 * 60.0)
                            Text("12小时").tag(12 * 60 * 60.0)
                            Text("24小时").tag(24 * 60 * 60.0)
                        }
                    }
                }
            }
            .navigationTitle("添加订阅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveSubscription()
                    }
                    .disabled(subscriptionName.isEmpty || subscriptionURL.isEmpty)
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveSubscription() {
        guard !subscriptionName.isEmpty && !subscriptionURL.isEmpty else {
            errorMessage = "请填写完整的订阅信息"
            showingError = true
            return
        }
        
        guard URL(string: subscriptionURL) != nil else {
            errorMessage = "请输入有效的订阅链接"
            showingError = true
            return
        }
        
        subscriptionManager.addSubscription(name: subscriptionName, url: subscriptionURL)
        
        // 等待订阅添加完成后再设置自动更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if autoUpdate {
                // 找到刚添加的订阅并设置自动更新
                if let newSubscription = subscriptionManager.subscriptions.last {
                    subscriptionManager.setAutoUpdate(newSubscription, enabled: true, interval: updateInterval)
                }
            }
        }
        
        dismiss()
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(SubscriptionManager())
}
