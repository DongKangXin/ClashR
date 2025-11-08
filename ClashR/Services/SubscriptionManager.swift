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
@MainActor
class SubscriptionManager: ObservableObject {
    private lazy var clashManager = ClashManager.share
    private lazy var clashApiService = ClashAPIService.shared
    private lazy var settings = Settings.shared
    

    
    // MARK: - Public Methods
    
    func testProxy(_ proxy : ClashProxy) async {
        do{
            let delayInfo = try await clashApiService.testProxyDelay(proxyName: proxy.name)
            settings.update(proxy){
                pro in pro.delay = delayInfo.delay
            }
        }catch{
            
        }
    }
    
    
    func testSubscription(_ proxys: [ClashProxy]) async {
        for proxy in proxys{
            Task{
                await testProxy(proxy)
            }
        }
    }
    
    
    func removeProxyNode(_ clashProxy: ClashProxy){
        settings.delete(clashProxy)
    }

    /// 添加订阅
    func addSubscription(name: String, url: String) {
        let subscription = Subscription(name: name, url: url)
        settings.insert(subscription)
    }

    /// 删除订阅
    func deleteSubscription(_ subscription: Subscription) {
        var nodes = settings.proxyNodes.filter{$0.subId == subscription.id}
        settings.delete(nodes)
        settings.delete(subscription)
    }

    /// 更新订阅
    func updateSubscription(_ subscription: Subscription) async ->[ClashProxy]  {

        do {
            let content = try await fetchSubscriptionContent(url: subscription.url)
            // 解析订阅内容并更新配置
            return parseClashProxy(content: content)
            
        } catch {
            print("更新订阅失败: \(error.localizedDescription)")
        }
        return []
    }
    

    /// 解析订阅内容并更新配置
    private func parseClashProxy(content: String) -> [ClashProxy] {
        do {
            // 尝试解析YAML格式
            if let yamlConfig = try? Yams.load(yaml: content) as? [String: Any] {
                return parseYAMLConfig(yamlConfig) ?? []
            }
            // 尝试解析JSON格式
            else if let jsonData = content.data(using: .utf8),
                    let jsonConfig = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                return parseJSONConfig(jsonConfig) ?? []
            }
            else {
                return []
            }
        } catch {
            print("解析订阅内容失败: \(error.localizedDescription)")
        }
    }

    /// 解析YAML配置
    private func parseYAMLConfig(_ config: [String: Any]) -> [ClashProxy]?  {
        var proxies: [ClashProxy] = []

        // 解析proxies
        if let proxiesArray = config["proxies"] as? [[String: Any]] {
            for proxyDict in proxiesArray {
                if(!["ss","hysteria2","trojan","vless","vmess"].contains(proxyDict["type"] as? String)){
                    continue
                }
                if(["ss"].contains(proxyDict["cipher"] as? String)){
                    continue
                }
                if let proxy = parseProxyFromDict(proxyDict) {
                    proxies.append(proxy)
                }
            }
        }
        return proxies;
    }

    /// 解析JSON配置
    private func parseJSONConfig(_ config: [String: Any]) -> [ClashProxy]?  {
        var proxies: [ClashProxy] = []

        // 解析proxies
        if let proxiesArray = config["proxies"] as? [[String: Any]] {
            for proxyDict in proxiesArray {
                if(!["ss","hysteria2","trojan","vless","vmess"].contains(proxyDict["type"] as? String)){
                    continue
                }
                if(["ss"].contains(proxyDict["cipher"] as? String)){
                    continue
                }
                if let proxy = parseProxyFromDict(proxyDict) {
                    proxies.append(proxy)
                }
            }
        }
        return proxies;

    }

    /// 从字典解析代理节点
    private func parseProxyFromDict(_ dict: [String: Any]) -> ClashProxy? {
        return ClashProxy.fromDict(dict)
    }

    /// 从字典解析代理组
    private func parseProxyGroupFromDict(_ dict: [String: Any]) -> ClashProxyGroup? {
        ClashProxyGroup.fromDict(dict)
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
