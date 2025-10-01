# ClashR for iOS

一个基于 SwiftUI 开发的 iOS Clash 客户端，采用最新的 iOS 和 Swift 特性。

## 功能特性

### 🚀 核心功能
- **代理服务控制**: 启动/停止代理服务，实时状态显示
- **配置管理**: 支持导入本地 YAML 配置文件，多配置管理
- **订阅功能**: 支持订阅链接，自动更新配置
- **模式切换**: Rule/Global/Direct 三种代理模式
- **节点管理**: 多节点选择，延迟测速功能
- **流量监控**: 实时上传/下载速度，今日流量统计
- **日志查看**: 实时日志输出，支持按级别过滤

### 🎨 界面设计
- **现代化 UI**: 基于 SwiftUI 构建，支持深色/浅色模式
- **卡片式布局**: 清晰的信息展示，优秀的用户体验
- **流畅动画**: 按钮点击反馈，页面切换动画
- **响应式设计**: 适配所有 iPhone 屏幕尺寸

### 🔧 技术特性
- **最新技术栈**: iOS 15+, Swift 5.9, SwiftUI
- **MVVM 架构**: 清晰的代码结构，易于维护
- **Combine 框架**: 响应式编程，状态管理
- **本地存储**: 配置文件本地保存，数据安全

## 项目结构

```
ClashR/
├── Models/           # 数据模型
│   └── ClashConfig.swift
├── Services/         # 服务层
│   ├── ClashService.swift
│   ├── ConfigManager.swift
│   └── SubscriptionManager.swift
├── Views/            # 视图层
│   ├── MainTabView.swift
│   ├── HomeView.swift
│   ├── ConfigView.swift
│   ├── SubscriptionView.swift
│   ├── ProxyView.swift
│   ├── LogView.swift
│   └── SettingsView.swift
├── ClashRApp.swift   # 应用入口
└── ContentView.swift # 主视图
```

## 开发环境

- **Xcode**: 15.0+
- **iOS**: 15.0+
- **Swift**: 5.9+
- **依赖**: Yams (YAML 解析)

## 安装依赖

项目使用 Swift Package Manager 管理依赖：

```bash
# 添加 Yams 依赖
.package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
```

## 使用说明

### 1. 配置管理
- 点击"配置"标签页
- 使用"+"按钮导入本地 YAML 配置文件
- 或手动添加配置内容
- 支持设置默认配置

### 2. 订阅管理
- 点击"订阅"标签页
- 添加订阅链接
- 支持自动更新设置
- 手动更新订阅内容

### 3. 代理控制
- 在首页点击"连接"按钮启动代理
- 选择代理模式（规则/全局/直连）
- 在"节点"页面选择代理节点
- 支持延迟测试功能

### 4. 流量监控
- 首页显示实时上传/下载速度
- 查看今日流量使用情况
- 支持清空今日流量统计

### 5. 日志查看
- 点击"日志"标签页
- 实时查看 Clash 内核日志
- 支持按级别过滤（INFO/WARN/ERROR）
- 可清空日志记录

## 开发计划

### 已完成 ✅
- [x] 项目基础架构搭建
- [x] 主界面导航和首页 Dashboard
- [x] 配置管理功能
- [x] 订阅管理功能
- [x] 代理服务控制
- [x] 模式切换和节点选择
- [x] 流量监控和日志查看
- [x] 设置页面和深色模式

### 待实现 🔄
- [ ] Clash 内核集成（xcframework）
- [ ] NetworkExtension 实现
- [ ] 真实延迟测试
- [ ] 配置文件验证
- [ ] 错误处理优化

## 注意事项

⚠️ **重要提醒**:
- 本项目为个人开源项目，不计划上架 App Store
- 需要集成 Clash 内核才能正常工作
- 建议通过 AltStore 或签名工具安装
- 请遵守当地法律法规使用

## 开源协议

本项目基于 MIT 协议开源，详见 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进项目。

## 联系方式

- GitHub: [your-username/ClashR](https://github.com/your-username/ClashR)
- Email: your-email@example.com

---

**免责声明**: 本项目仅供学习和研究使用，请用户自行承担使用风险。
