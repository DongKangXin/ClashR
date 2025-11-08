# Clash HTTP API 服务使用说明

## 概述

本项目已经集成了完整的 Clash.meta HTTP API 服务，提供了与 Clash 内核的完整交互功能。

## 主要功能

### 1. ClashAPIService 类

位置：`ClashR/Services/ClashAPIService.swift`

这是核心的 API 服务类，提供了以下功能：

- **日志管理**：实时获取 Clash 内核日志
- **流量监控**：获取实时流量统计
- **内存监控**：获取内存使用情况
- **代理管理**：获取代理列表、选择代理、测试延迟
- **代理组管理**：管理代理组、测试延迟
- **连接管理**：查看和管理连接
- **配置管理**：获取和更新配置
- **缓存管理**：清除 FakeIP 缓存
- **内核控制**：重启内核

### 2. 日志页面

位置：`ClashR/Views/LogView.swift`

提供了完整的日志查看界面：

- **实时日志**：自动刷新显示最新日志
- **日志级别过滤**：支持按 info、debug、warning、error 过滤
- **搜索功能**：支持搜索日志内容
- **自动滚动**：可选择是否自动滚动到最新日志
- **日志操作**：清空日志、刷新、重启内核

### 3. 数据模型

位置：`ClashR/Services/Models/ClashConfig.swift`

更新了 LogLevel 枚举，支持：
- all（全部）
- debug（调试）
- info（信息）
- warning（警告）
- error（错误）

## API 端点说明

### 日志相关
- `GET /logs` - 获取实时日志
- `GET /logs?level=log_level` - 获取指定级别日志

### 流量和内存
- `GET /traffic` - 获取实时流量（kbps）
- `GET /memory` - 获取内存使用（kb）

### 代理管理
- `GET /proxies` - 获取所有代理信息
- `GET /proxies/{name}` - 获取特定代理信息
- `PUT /proxies/{name}` - 选择特定代理
- `GET /proxies/{name}/delay` - 测试代理延迟

### 代理组管理
- `GET /group` - 获取代理组信息
- `GET /group/{name}` - 获取特定代理组信息
- `GET /group/{name}/delay` - 测试代理组延迟

### 连接管理
- `GET /connections` - 获取连接信息
- `DELETE /connections` - 关闭所有连接
- `DELETE /connections/{id}` - 关闭特定连接

### 配置管理
- `GET /configs` - 获取基本配置
- `PUT /configs?force=true` - 重新加载配置
- `PATCH /configs` - 更新配置

### 其他功能
- `GET /version` - 获取版本信息
- `POST /cache/fakeip/flush` - 清除 FakeIP 缓存
- `POST /restart` - 重启内核

## 使用方法

### 1. 在视图中使用 API 服务

```swift
@StateObject private var apiService = ClashAPIService.shared

// 获取日志
Task {
    await apiService.fetchLogs(level: .info)
}

// 获取流量信息
Task {
    await apiService.fetchTraffic()
}

// 选择代理
Task {
    try await apiService.selectProxy(proxyName: "代理组名", selectedProxy: "代理名")
}
```

### 2. 监听数据变化

```swift
// 监听日志变化
apiService.$logs
    .sink { logs in
        // 处理日志更新
    }
    .store(in: &cancellables)

// 监听流量变化
apiService.$traffic
    .sink { traffic in
        // 处理流量更新
    }
    .store(in: &cancellables)
```

## 配置说明

### API 配置

在 `ClashAPIService.swift` 中可以配置：

```swift
private let baseURL = "http://127.0.0.1:9090"  // API 地址
private let secret = ""  // API 密钥（如果配置了的话）
```

### Clash 配置

确保 Clash 配置文件中包含：

```yaml
external-controller: '0.0.0.0:9090'  # API 监听地址
# secret: 'your-secret-key'  # 可选：API 密钥
```

## 注意事项

1. **网络权限**：确保应用有网络访问权限
2. **API 地址**：默认使用 `127.0.0.1:9090`，确保与 Clash 配置一致
3. **错误处理**：所有 API 调用都包含错误处理，建议在调用时使用 try-catch
4. **内存管理**：日志会自动限制数量（最多1000条），避免内存过多占用
5. **实时更新**：日志和流量信息会自动定时更新

## 扩展功能

可以基于现有的 API 服务扩展更多功能：

- 代理延迟测试页面
- 连接管理页面
- 流量统计图表
- 配置编辑器
- 代理组管理界面

## 故障排除

1. **API 连接失败**：检查 Clash 是否启动，API 地址是否正确
2. **日志不显示**：检查 Clash 的日志级别设置
3. **权限问题**：确保应用有必要的网络权限
4. **数据不更新**：检查定时器是否正常工作
