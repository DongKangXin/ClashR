//
//  LogView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/5.
//

import SwiftUI

/// 日志页面视图
struct LogView: View {
    
    @StateObject private var apiService = ClashAPIService.shared
    @State private var selectedLogLevel: LogLevel = .info
    @State private var isAutoScroll = true
    @State private var searchText = ""
    
    @State private var showLogSheet = false
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 日志列表
                logListView
            }
            .navigationTitle("日志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("清空日志") {
                            apiService.clearLogs()
                        }
                        
                        
                        Button("重启内核") {
                            Task {
                                try? await apiService.restart()
                            }
                        }
                        Button("查看日志文件") {
                            withAnimation {
                                showLogSheet.toggle()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    LogLevelSelector(
                        selectedLevel: $selectedLogLevel,
                        isCompact: true
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogViewSheet(isPresented: $showLogSheet)
            }
        }
    }

    
    // MARK: - Log List View
    
    private var logListView: some View {
        ScrollViewReader { proxy in
            List(filteredLogs) { log in
                LogRowView(log: log)
                    .id(log.id)
            }
            .onChange(of: apiService.logs.count) { _ in
                if isAutoScroll && !apiService.logs.isEmpty {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(apiService.logs.last?.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredLogs: [ClashLogEntry] {
        var logs = apiService.logs
        
        // 按日志级别过滤
        if selectedLogLevel != .all {
            logs = logs.filter { log in
                log.type.lowercased() == selectedLogLevel.rawValue.lowercased()
            }
        }
        
        // 按搜索文本过滤
        if !searchText.isEmpty {
            logs = logs.filter { log in
                log.payload.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return logs
    }
}

// MARK: - Log Row View

struct LogRowView: View {
    let log: ClashLogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 时间戳和日志级别
            HStack {
                Text(formatTime(log.time))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                LogLevelBadge(level: log.type)
            }
            
            // 日志内容
            Text(log.payload)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(logColor(for: log.type))
                .lineLimit(nil)
        }
        .padding(.vertical, 2)
    }
    
    private func formatTime(_ time: Date) -> String {
        // 解析时间字符串并格式化
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MM-dd HH:mm:ss"
        return formatter.string(from: time)
       
    }
    
    private func logColor(for level: String) -> Color {
        switch level.lowercased() {
        case "error":
            return .red
        case "warning":
            return .orange
        case "info":
            return .primary
        case "debug":
            return .blue
        default:
            return .primary
        }
    }
}

// MARK: - Log Level Badge

struct LogLevelBadge: View {
    let level: String
    
    var body: some View {
        Text(level.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch level.lowercased() {
        case "error":
            return .red.opacity(0.2)
        case "warning":
            return .orange.opacity(0.2)
        case "info":
            return .blue.opacity(0.2)
        case "debug":
            return .green.opacity(0.2)
        default:
            return .gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch level.lowercased() {
        case "error":
            return .red
        case "warning":
            return .orange
        case "info":
            return .blue
        case "debug":
            return .green
        default:
            return .gray
        }
    }
}

// 日志级别选择器组件
struct LogLevelSelector: View {
    @Binding var selectedLevel: LogLevel
    let isCompact: Bool
    
    var body: some View {
        if isCompact {
            Menu {
                ForEach(LogLevel.allCases, id: \.displayName) { level in
                    Button() {
                        selectedLevel = level
                    } label:{
                        Image(systemName: level.icon)
                            .foregroundColor(level.color)
                            .contentShape(Rectangle()) // 确保整个区域可点击
                        // 使用更短的文字
                        Text(level.displayName) // 比如 "全部" → "全"
                            .font(.subheadline)
                    
                    }
                }
            } label: {
                Image(systemName: selectedLevel.icon)
                    .foregroundColor(selectedLevel.color)
            }.tint(.primary) 
        } else {
            // 完整模式：底部工具栏样式
            VStack(spacing: 8) {
                Picker("日志级别", selection: $selectedLevel) {
                    ForEach(LogLevel.allCases,id: \.displayName) { level in
                        Text(level.rawValue)
                            .tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct LogViewSheet: View {
    @EnvironmentObject var clashManager: ClashManager
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    
    @State private var logContent: String = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // 日志内容
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("加载中...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if logContent.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("暂无日志")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(logContent)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("日志")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { loadLogs() }) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Label("刷新", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadLogs()
            }
        }
    }
    
    private func loadLogs() {
        isLoading = true
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            do {
                let content = try clashManager.readLogFile()
                
                DispatchQueue.main.async {
                    logContent = content
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    logContent = "读取日志失败: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func clearLogs() {
        
    }
}


// MARK: - Preview

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView()
    }
}
