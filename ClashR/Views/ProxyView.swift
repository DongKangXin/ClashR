//
//  ProxyView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI

/// 节点管理页面
struct ProxyView: View {
    @EnvironmentObject var clashService: ClashService
    @State private var selectedGroup: String?
    @State private var testingNodes: Set<String> = []
    
    // 按类型分组节点
    private var groupedNodes: [String: [ProxyNode]] {
        Dictionary(grouping: clashService.proxyNodes) { node in
            node.type.uppercased()
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if clashService.proxyNodes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "network")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("暂无节点")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("请先导入配置文件或更新订阅")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(Array(groupedNodes.keys.sorted()), id: \.self) { groupName in
                        Section(groupName) {
                            ForEach(groupedNodes[groupName] ?? []) { node in
                                ProxyNodeRowView(
                                    node: node,
                                    isTesting: testingNodes.contains(node.id)
                                )
                                .environmentObject(clashService)
                                .onTapGesture {
                                    Task {
                                        await clashService.selectNode(node)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(action: {
                                        Task {
                                            testingNodes.insert(node.id)
                                            await clashService.testNodeLatency(node)
                                            testingNodes.remove(node.id)
                                        }
                                    }) {
                                        Label("测试", systemImage: "speedometer")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("节点管理")
            .refreshable {
                await refreshNodes()
            }
        }
    }
    
    private func refreshNodes() async {
        // 重新加载节点列表
        await clashService.loadProxyNodes()
    }
}

/// 节点行视图
struct ProxyNodeRowView: View {
    let node: ProxyNode
    let isTesting: Bool
    @EnvironmentObject var clashService: ClashService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(node.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if node.isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text("\(node.server):\(node.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let latency = node.latency {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(latencyColor(latency))
                            .font(.caption)
                        
                        Text("\(latency)ms")
                            .font(.caption)
                            .foregroundColor(latencyColor(latency))
                    }
                } else if isTesting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("测试中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(node.type.uppercased())
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor(node.type))
                    .cornerRadius(4)
                
                if node.isSelected {
                    Text("当前")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func latencyColor(_ latency: Int) -> Color {
        if latency < 100 {
            return .green
        } else if latency < 300 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func typeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "ss", "shadowsocks":
            return .blue
        case "ssr", "shadowsocksr":
            return .purple
        case "vmess":
            return .green
        case "trojan":
            return .red
        case "vless":
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    ProxyView()
        .environmentObject(ClashService())
}
