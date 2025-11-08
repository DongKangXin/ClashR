//
//  Settings.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/22.
//
import Foundation
import Combine
import UIKit
import SwiftUI
import SwiftData

extension UserDefaults {
    func set<T: Encodable>(_ object: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(object) {
            self.set(encoded, forKey: key)
        }
    }
    
    func object<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        if let data = self.data(forKey: key),
           let decoded = try? JSONDecoder().decode(T.self, from: data) {
            return decoded
        }
        return nil
    }
}


@MainActor
class Settings: ObservableObject {
    
    static let shared = Settings()

    @AppStorage("enableLinkActivity")
    var enableLinkActivity: Bool = false
    
    @AppStorage("proxyMode" )
    var proxyMode: ProxyMode = ProxyMode.rule
    
    @AppStorage("autoProxy")
    var autoProxy: Bool = true
    
    @AppStorage("selectProxy")
    var selectProxy: String?
    
    @AppStorage("logLevel")
    var logLevel: String = "info"
    
    @Published var subscriptions: [Subscription] = []
    
    @Published var proxyNodes: [ClashProxy] = []
    
    // ✅ 用 @MainActor 确保在主线程访问
    @MainActor
    private var modelContext: ModelContext?
    
    // ✅ 设置 modelContext
    @MainActor
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSubscriptions()
        loadProxyNodes()
    }
    
    // ✅ 加载订阅
    @MainActor
    private func loadSubscriptions() {
        do {
            let descriptor = FetchDescriptor<Subscription>()
            subscriptions = try modelContext?.fetch(descriptor) ?? []
        } catch {
            print("❌ 加载失败: \(error)")
        }
    }
    
    // ✅ 加载代理节点
    @MainActor
    private func loadProxyNodes() {
        do {
            let descriptor = FetchDescriptor<ClashProxy>()
            proxyNodes = try modelContext?.fetch(descriptor) ?? []
        } catch {
            print("❌ 加载失败: \(error)")
        }
    }
    
    // ✅ 统一的 save 方法
    @MainActor
    private func save() {
        do {
            try modelContext?.save()
            loadSubscriptions()
            loadProxyNodes()
            print("✅ 保存成功")
        } catch {
            print("❌ 保存失败: \(error)")
        }
    }
    
    // ✅ 统一的 delete 方法
    @MainActor
    func delete<T: PersistentModel>(_ model: T) {
        modelContext?.delete(model)
        save()
    }
    
    // ✅ 统一的 delete 方法 - 批量
    func delete<T: PersistentModel>(_ models: [T]) {
        models.forEach { modelContext?.delete($0) }
        save()
    }
    
    // ✅ 统一的 insert 方法
    @MainActor
    func insert<T: PersistentModel>(_ model: T) {
        modelContext?.insert(model)
        save()
    }
    // ✅ 统一的 delete 方法 - 批量
    @MainActor
    func insert<T: PersistentModel>(_ models: [T]) {
        models.forEach { modelContext?.insert($0) }
        save()
    }
    
    // ✅ 统一的 update 方法
    @MainActor
    func update<T: PersistentModel>(_ model: T, changes: (T) -> Void) {
        changes(model)
        save()
    }
    // ✅ 统一的 update 方法
    @MainActor
    func update<T: PersistentModel>(_ models: [T], changes: (T) -> Void) {
        models.forEach { changes($0)}
        save()
    }
}

/// 代理模式枚举
enum ProxyMode: String, CaseIterable, Codable {
    case rule = "Rule"
    case global = "Global"
    case direct = "Direct"
    
    var displayName: String {
        switch self {
        case .rule: return "规则模式"
        case .global: return "全局模式"
        case .direct: return "直连模式"
        }
    }
    
    var icon: String {
        switch self {
        case .rule: return "list.bullet"
        case .global: return "globe"
        case .direct: return "arrow.right"
        }
    }
    
}
