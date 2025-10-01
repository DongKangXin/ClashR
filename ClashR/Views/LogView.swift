//
//  LogView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI

/// 日志查看页面
struct LogView: View {
    @EnvironmentObject var clashService: ClashService
    @State private var scrollToBottom = false
    
    // 过滤后的日志
    private var filteredLogs: [LogEntry] {
        clashService.logs.filter { log in
            clashService.selectedLogLevel == .info || log.level == clashService.selectedLogLevel
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 日志级别过滤器
                LogLevelFilter()
                    .environmentObject(clashService)
                
                Divider()
                
                // 日志列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredLogs) { log in
                                LogEntryView(log: log)
                                    .id(log.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: clashService.logs.count) { _ in
                        if let lastLog = clashService.logs.last {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 底部操作栏
                LogActionBar()
                    .environmentObject(clashService)
            }
            .navigationTitle("日志")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 日志级别过滤器
struct LogLevelFilter: View {
    @EnvironmentObject var clashService: ClashService
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    Button(action: {
                        clashService.selectedLogLevel = level
                    }) {
                        Text(level.rawValue)
                            .font(.caption)
                            .foregroundColor(clashService.selectedLogLevel == level ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(clashService.selectedLogLevel == level ? Color.blue : Color(.systemGray6))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

/// 日志条目视图
struct LogEntryView: View {
    let log: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 时间戳
            Text(log.timestamp.formatted(date: .omitted, time: .standard))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            // 日志级别
            Text(log.level.rawValue)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(levelColor(log.level))
                .cornerRadius(4)
                .frame(width: 50, alignment: .center)
            
            // 日志内容
            Text(log.message)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 2)
    }
    
    private func levelColor(_ level: LogLevel) -> Color {
        switch level {
        case .info: return .blue
        case .warn: return .orange
        case .error: return .red
        case .debug: return .gray
        }
    }
}

/// 日志操作栏
struct LogActionBar: View {
    @EnvironmentObject var clashService: ClashService
    @State private var showingClearAlert = false
    
    var body: some View {
        HStack {
            Text("共 \(clashService.logs.count) 条日志")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: {
                showingClearAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("清空")
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .alert("清空日志", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                clashService.clearLogs()
            }
        } message: {
            Text("确定要清空所有日志吗？此操作不可撤销。")
        }
    }
}

#Preview {
    LogView()
        .environmentObject(ClashService())
}
