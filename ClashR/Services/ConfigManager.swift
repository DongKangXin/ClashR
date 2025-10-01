//
//  ConfigManager.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import Combine
import Foundation
import Yams

/// 配置管理器
class ConfigManager: ObservableObject {
    @Published var configs: [ClashConfig] = []
    @Published var defaultConfigId: UUID?
    
    private let documentsDirectory: URL
    private let configsDirectory: URL
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        configsDirectory = documentsDirectory.appendingPathComponent("Configs")
        
        createConfigsDirectoryIfNeeded()
        loadConfigs()
    }
    
    // MARK: - Public Methods
    
    /// 导入配置文件
    func importConfig(from url: URL, name: String) throws -> ClashConfig {
        // 验证YAML文件格式
        let yamlContent = try String(contentsOf: url)
        _ = try Yams.load(yaml: yamlContent) as? [String: Any]
        
        // 复制文件到配置目录
        let fileName = "\(UUID().uuidString).yaml"
        let destinationURL = configsDirectory.appendingPathComponent(fileName)
        
        try FileManager.default.copyItem(at: url, to: destinationURL)
        
        // 创建配置对象
        let config = ClashConfig(name: name, filePath: destinationURL.path)
        
        // 保存配置
        configs.append(config)
        saveConfigs()
        
        return config
    }
    
    /// 添加订阅配置
    func addSubscriptionConfig(name: String, yamlContent: String) throws -> ClashConfig {
        // 验证YAML格式
        _ = try Yams.load(yaml: yamlContent) as? [String: Any]
        
        // 保存YAML内容到文件
        let fileName = "\(UUID().uuidString).yaml"
        let fileURL = configsDirectory.appendingPathComponent(fileName)
        
        try yamlContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // 创建配置对象
        let config = ClashConfig(name: name, filePath: fileURL.path)
        
        // 保存配置
        configs.append(config)
        saveConfigs()
        
        return config
    }
    
    /// 删除配置
    func deleteConfig(_ config: ClashConfig) throws {
        // 删除文件
        try FileManager.default.removeItem(atPath: config.filePath)
        
        // 从列表中移除
        configs.removeAll { $0.id == config.id }
        
        // 如果删除的是默认配置，清除默认配置
        if defaultConfigId == config.id {
            defaultConfigId = nil
        }
        
        saveConfigs()
    }
    
    /// 设置默认配置
    func setDefaultConfig(_ config: ClashConfig) {
        defaultConfigId = config.id
        saveConfigs()
    }
    
    /// 获取默认配置
    func getDefaultConfig() -> ClashConfig? {
        guard let defaultId = defaultConfigId else { return configs.first }
        return configs.first { $0.id == defaultId }
    }
    
    /// 更新配置
    func updateConfig(_ config: ClashConfig) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            var updatedConfig = config
            updatedConfig.updatedAt = Date()
            configs[index] = updatedConfig
            saveConfigs()
        }
    }
    
    /// 验证配置文件
    func validateConfig(at url: URL) throws -> Bool {
        let yamlContent = try String(contentsOf: url)
        _ = try Yams.load(yaml: yamlContent) as? [String: Any]
        return true
    }
    
    // MARK: - Private Methods
    
    /// 创建配置目录
    private func createConfigsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: configsDirectory.path) {
            try? FileManager.default.createDirectory(at: configsDirectory, withIntermediateDirectories: true)
        }
    }
    
    /// 加载配置列表
    private func loadConfigs() {
        // 从UserDefaults加载配置信息
        if let configsData = userDefaults.data(forKey: "ClashConfigs"),
           let loadedConfigs = try? JSONDecoder().decode([ClashConfig].self, from: configsData) {
            configs = loadedConfigs
        }
        
        // 从UserDefaults加载默认配置ID
        if let defaultIdString = userDefaults.string(forKey: "DefaultConfigId"),
           let defaultId = UUID(uuidString: defaultIdString) {
            defaultConfigId = defaultId
        }
        
        // 验证配置文件是否仍然存在
        configs = configs.filter { FileManager.default.fileExists(atPath: $0.filePath) }
        
        // 如果没有配置，创建示例配置
        if configs.isEmpty {
            createSampleConfig()
        }
    }
    
    /// 保存配置列表
    private func saveConfigs() {
        if let configsData = try? JSONEncoder().encode(configs) {
            userDefaults.set(configsData, forKey: "ClashConfigs")
        }
        
        if let defaultId = defaultConfigId {
            userDefaults.set(defaultId.uuidString, forKey: "DefaultConfigId")
        }
    }
    
    /// 创建示例配置
    private func createSampleConfig() {
        let sampleYaml = """
        port: 7890
        socks-port: 7891
        allow-lan: false
        mode: rule
        log-level: info
        external-controller: 127.0.0.1:9090
        
        proxies:
          - name: "direct"
            type: direct
            
        proxy-groups:
          - name: "PROXY"
            type: select
            proxies:
              - direct
              
        rules:
          - MATCH,PROXY
        """
        
        do {
            let fileName = "\(UUID().uuidString).yaml"
            let fileURL = configsDirectory.appendingPathComponent(fileName)
            
            try sampleYaml.write(to: fileURL, atomically: true, encoding: .utf8)
            
            let config = ClashConfig(name: "示例配置", filePath: fileURL.path, isDefault: true)
            configs.append(config)
            defaultConfigId = config.id
            
            saveConfigs()
        } catch {
            print("创建示例配置失败: \(error)")
        }
    }
}
