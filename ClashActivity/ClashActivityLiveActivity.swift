//
//  ClashActivityLiveActivity.swift
//  ClashActivity
//
//  Created by 董康鑫 on 2025/10/23.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - ActivityAttributes 定义
struct ClashActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var showDownload: Bool
        var proxyName: String
        var proxyMode: String
        var downloadSpeed: String
        var uploadSpeed: String
        var latency: String
        var time: String
        var speedHistory: ChartData
    }
    
    var clashVersion: String
}

struct ChartDataPoint: Codable, Hashable {
    let value: Double
    let timestamp: Date
}

struct ChartData: Codable, Hashable {
    var dataPoints: [ChartDataPoint] = []
    
    mutating func addPoint(_ value: Double) {
        dataPoints.append(ChartDataPoint(value: value, timestamp: Date()))
        
        // 只保留最近 20 个数据点
        if dataPoints.count > 20 {
            dataPoints.removeFirst()
        }
    }
    
    var maxValue: Double {
        dataPoints.map { $0.value }.max() ?? 100
    }
    
    var minValue: Double {
        dataPoints.map { $0.value }.min() ?? 0
    }
}

struct LockScreenView: View {
    
    let context: ActivityViewContext<ClashActivityAttributes>
    @State private var displayTime: String = ""
    @State private var secondsCounter: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        
        // ✅ 锁屏/横幅视图 - 使用 context 数据
        VStack(spacing: 8) {
            // 顶部：代理信息
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(context.state.proxyName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                
                Spacer()
            }
            
            // 速度信息
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12))
                    Text(context.state.uploadSpeed)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.green)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12))
                    Text(context.state.downloadSpeed)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.blue)
               
                
                Spacer()
                // ✅ 显示定时更新的时间
                Text(context.state.time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}


// MARK: - 灵动岛 Widget
struct ClashActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClashActivityAttributes.self) { context in
            LockScreenView(context: context)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        HStack{
                            Text("Clash")
                                .font(.system(size: 14, weight: .semibold))
                            // ✅ 显示定时更新的时间
                           
                        }
                        // ✅ 下方：折线图（占据整个宽度）
                        SimpleChartView(
                            chartData: context.state.speedHistory
                        )
                        .frame(width: 150,height: 45)
                        Text(context.state.time)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                    }
                    .padding()
                }
                // 展开视图 - 左侧
                DynamicIslandExpandedRegion(.leading) {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "link.icloud.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("代理模式")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                
                                Text(context.state.proxyMode)
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "globe.americas.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("代理节点")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(context.state.proxyName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                }
                
                // 展开视图 - 右侧
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 16) {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12))
                            Text(context.state.uploadSpeed)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.green)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 12))
                            Text(context.state.downloadSpeed)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        Spacer()
                        
                    }
                }
                
//                // 展开视图 - 底部（可选）
//                DynamicIslandExpandedRegion(.bottom) {
//                    VStack{
//                        HStack{
//                            Spacer()
//                            // ✅ 显示定时更新的时间
//                            Text(context.state.time)
//                                .font(.caption2)
//                                .foregroundColor(.gray)
//                            Spacer()
//                        }
//                        Spacer()
//                    }
//                }
                
            } compactLeading: {
                // 紧凑状态 - 左侧
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text(context.state.proxyName)
                        .font(.system(size: 10, weight: .semibold))
                        .lineLimit(1)
                }
                
            } compactTrailing: {
                // 紧凑状态 - 右侧
                HStack(spacing: 3) {
                    if context.state.showDownload {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                        
                        Text(context.state.downloadSpeed)
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                    }else{
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        
                        Text(context.state.uploadSpeed)
                            .font(.system(size: 9, weight: .medium))
                            .lineLimit(1)
                    }
                    
                }
                
            } minimal: {
                // 最小化状态
                Image(systemName: "network")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .keylineTint(.blue)
        }
    }
}
