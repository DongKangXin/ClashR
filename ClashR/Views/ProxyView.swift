////
////  ProxyView.swift
////  ClashR
////
////  Created by 董康鑫 on 2025/10/1.
////
//
//import SwiftUI
//
///// 节点选择页面
//struct ProxyView: View {
//    @EnvironmentObject var clashService: ClashService
//    @State private var selectedProxy: ProxyNode?
//    @State private var isTestingLatency = false
//    
//    var body: some View {
//        NavigationView {
//            List {
//                if clashService.proxyNodes.isEmpty {
//                    VStack(spacing: 16) {
//                        Image(systemName: "network")
//                            .font(.system(size: 60))
//                            .foregroundColor(.gray)
//                        
//                        Text("暂无节点")
//                            .font(.title2)
//                            .foregroundColor(.primary)
//                        
//                        Text("请先添加订阅获取节点")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 40)
//                    .listRowBackground(Color.clear)
//                } else {
//                    ForEach(clashService.proxyNodes) { proxy in
//                        ProxyRowView(proxy: proxy, isSelected: selectedProxy?.id == proxy.id)
//                            .onTapGesture {
//                                selectedProxy = proxy
//                                clashService.proxyNodes.indices.forEach { index in
//                                    clashService.proxyNodes[index].isSelected = (clashService.proxyNodes[index].id == proxy.id)
//                                }
//                            }
//                    }
//                }
//            }
//            .navigationTitle("节点选择")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        Task {
//                            isTestingLatency = true
//                            await clashService.testAllNodesLatency()
//                            isTestingLatency = false
//                        }
//                    }) {
//                        if isTestingLatency {
//                            ProgressView()
//                                .scaleEffect(0.8)
//                        } else {
//                            Image(systemName: "speedometer")
//                        }
//                    }
//                    .disabled(clashService.proxyNodes.isEmpty || isTestingLatency)
//                }
//            }
//        }
//    }
//}
//
///// 节点行视图
//struct ProxyRowView: View {
//    let proxy: ProxyNode
//    let isSelected: Bool
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            // 节点图标
//            Image(systemName: proxyIcon)
//                .foregroundColor(.blue)
//                .font(.title2)
//                .frame(width: 30)
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(proxy.name)
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                
//                HStack {
//                    Text("\(proxy.server):\(proxy.port)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    if let latency = proxy.latency {
//                        Text("• \(latency)ms")
//                            .font(.caption)
//                            .foregroundColor(latencyColor(latency))
//                    }
//                }
//            }
//            
//            Spacer()
//            
//            // 选中状态
//            if isSelected {
//                Image(systemName: "checkmark.circle.fill")
//                    .foregroundColor(.blue)
//                    .font(.title3)
//            }
//        }
//        .padding(.vertical, 8)
//        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
//        .cornerRadius(8)
//    }
//    
//    private var proxyIcon: String {
//        switch proxy.type.lowercased() {
//        case "ss", "shadowsocks": return "network"
//        case "trojan": return "shield.fill"
//        case "vmess": return "globe"
//        case "vless": return "globe"
//        default: return "network"
//        }
//    }
//    
//    private func latencyColor(_ latency: Int) -> Color {
//        if latency < 100 {
//            return .green
//        } else if latency < 300 {
//            return .orange
//        } else {
//            return .red
//        }
//    }
//}
//
//#Preview {
//    ProxyView()
//        .environmentObject(ClashService.share)
//}
