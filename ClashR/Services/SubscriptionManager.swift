//
//  SubscriptionManager.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import Foundation
import Combine
import Yams

/// 订阅管理器
class SubscriptionManager: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private var updateTimers: [UUID: Timer] = [:]
    
    // MARK: - Initialization
    init() {
        loadSubscriptions()
        setupAutoUpdateTimers()
    }
    
    deinit {
        updateTimers.values.forEach { $0.invalidate() }
    }
    
    // MARK: - Public Methods
    
    /// 添加订阅
    func addSubscription(name: String, url: String) {
        let subscription = Subscription(name: name, url: url)
        subscriptions.append(subscription)
        print("添加订阅: \(subscription.name), 总数: \(subscriptions.count)")
        saveSubscriptions()
        
        // 立即更新一次
        Task {
            await updateSubscription(subscription)
        }
    }
    
    /// 删除订阅
    func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        updateTimers[subscription.id]?.invalidate()
        updateTimers.removeValue(forKey: subscription.id)
        saveSubscriptions()
    }
    
    /// 更新订阅
    func updateSubscription(_ subscription: Subscription) async {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }
        
        do {
            // 获取订阅内容
            let yamlContent = try await fetchSubscriptionContent(url: subscription.url)
            
            // 验证YAML格式
            _ = try Yams.load(yaml: yamlContent) as? [String: Any]
            
            // 更新订阅信息
            subscriptions[index].lastUpdate = Date()
            
            // 保存到配置文件
            let configManager = ConfigManager()
            let config = try configManager.addSubscriptionConfig(name: subscription.name, yamlContent: yamlContent)
            
            // 保存订阅列表（这会触发UI更新）
            saveSubscriptions()
            
        } catch {
            print("更新订阅失败: \(error.localizedDescription)")
            // 即使更新失败，也要保存订阅列表以更新UI
            saveSubscriptions()
        }
    }
    
    /// 手动更新所有订阅
    func updateAllSubscriptions() async {
        for subscription in subscriptions where subscription.isEnabled {
            await updateSubscription(subscription)
        }
    }
    
    /// 切换订阅启用状态
    func toggleSubscription(_ subscription: Subscription) {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }
        
        subscriptions[index].isEnabled.toggle()
        
        if subscriptions[index].isEnabled {
            setupAutoUpdateTimer(for: subscriptions[index])
        } else {
            updateTimers[subscription.id]?.invalidate()
            updateTimers.removeValue(forKey: subscription.id)
        }
        
        // 保存订阅列表（这会触发UI更新）
        saveSubscriptions()
    }
    
    /// 设置自动更新
    func setAutoUpdate(_ subscription: Subscription, enabled: Bool, interval: TimeInterval) {
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else { return }
        
        subscriptions[index].autoUpdate = enabled
        subscriptions[index].updateInterval = interval
        
        if enabled {
            setupAutoUpdateTimer(for: subscriptions[index])
        } else {
            updateTimers[subscription.id]?.invalidate()
            updateTimers.removeValue(forKey: subscription.id)
        }
        
        // 保存订阅列表（这会触发UI更新）
        saveSubscriptions()
    }
    
    // MARK: - Private Methods
    
    /// 加载订阅列表
    private func loadSubscriptions() {
        if let subscriptionsData = userDefaults.data(forKey: "ClashSubscriptions"),
           let loadedSubscriptions = try? JSONDecoder().decode([Subscription].self, from: subscriptionsData) {
            subscriptions = loadedSubscriptions
        }
    }
    
    /// 保存订阅列表
    private func saveSubscriptions() {
        if let subscriptionsData = try? JSONEncoder().encode(subscriptions) {
            userDefaults.set(subscriptionsData, forKey: "ClashSubscriptions")
            print("保存订阅列表: \(subscriptions.count) 个订阅")
        }
    }
    
    /// 设置自动更新定时器
    private func setupAutoUpdateTimers() {
        for subscription in subscriptions where subscription.isEnabled && subscription.autoUpdate {
            setupAutoUpdateTimer(for: subscription)
        }
    }
    
    /// 为单个订阅设置自动更新定时器
    private func setupAutoUpdateTimer(for subscription: Subscription) {
        // 取消现有定时器
        updateTimers[subscription.id]?.invalidate()
        
        // 创建新的定时器
        let timer = Timer.scheduledTimer(withTimeInterval: subscription.updateInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.updateSubscription(subscription)
            }
        }
        
        updateTimers[subscription.id] = timer
    }
    
    /// 获取订阅内容
    private func fetchSubscriptionContent(url: String) async throws -> String {
        guard let url = URL(string: url) else {
            throw SubscriptionError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubscriptionError.networkError
        }
        
        // 尝试Base64解码
        if let base64String = String(data: data, encoding: .utf8),
           let decodedData = Data(base64Encoded: base64String),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            return decodedString
        }
        
        // 如果不是Base64编码，直接返回原始内容
        guard let content = String(data: data, encoding: .utf8) else {
            throw SubscriptionError.invalidContent
        }
        
        return content
    }
}

// MARK: - Subscription Errors
enum SubscriptionError: LocalizedError {
    case invalidURL
    case networkError
    case invalidContent
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的订阅链接"
        case .networkError:
            return "网络请求失败"
        case .invalidContent:
            return "订阅内容格式错误"
        }
    }
}
