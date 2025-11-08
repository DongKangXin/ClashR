//
//  HomeView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/1.
//

import SwiftUI
import SwiftData

/// 首页Dashboard视图
struct HomeView: View {
    @EnvironmentObject var clashService: ClashService
    @EnvironmentObject var clashManager: ClashManager
    @EnvironmentObject var vpnManager: VPNManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var clashApiService: ClashAPIService
    @EnvironmentObject var settings: Settings
    @Query(sort:\Subscription.createAt) private var subscriptions:[Subscription]
    @Query(sort:\ClashProxy.createAt) private var proxyNodes:[ClashProxy]
    
    @State private var showingAddSubscription = false
    
    @State private var subscriptionName = ""
    @State private var subscriptionURL = ""



    var body: some View {
        NavigationStack {
            List {
                // 代理控制卡片（合并状态和模式）
                ProxyControlCard()
                ForEach(subscriptions) { subscription in
                    // 每个订阅作为独立行，支持展开/折叠
                    Section{
                        SubscriptionRow(
                            subscription: subscription
                        )
                        
                        // ✅ 只显示该订阅的代理
                        if subscription.isExpand {
                            ForEach(proxyNodes.filter { $0.subId == subscription.id }) { proxy in
                                ProxyRow(proxy: proxy)
                            }
                        }
                
                    }
                }

            }
            .animation(nil, value: subscriptions)
            .navigationTitle("Clash")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                
                ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            withAnimation{
                                showingAddSubscription.toggle()
                            }
                        }) {
                            Image(systemName: "plus")
                        }
                        .tint(.blue)

                }
                
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented:$showingAddSubscription)
            {
                AddSubscriptionView()
                    .presentationDetents([.fraction(0.4), .large])
                    .presentationDragIndicator(.visible)
             
            }
                
        }
    }
}

struct AddSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var subscriptionName = ""
    @State private var subscriptionURL = ""
    var body: some View {
        NavigationStack{
            VStack{
                Form {
                    Section {
                        TextField("订阅名称", text: $subscriptionName)
                        TextField("订阅网址", text: $subscriptionURL)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                }
                // ✅ Form 样式设置
//                .scrollContentBackground(.hidden)
//                .background(Color.clear)
            }
            .navigationTitle("添加订阅")
            .navigationBarTitleDisplayMode(.inline)
      
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation{
                            subscriptionManager.addSubscription(name: subscriptionName, url: subscriptionURL)
                            subscriptionName = ""
                            subscriptionURL = ""
                            dismiss()
                        }
                    }) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(subscriptionName.isEmpty || subscriptionURL.isEmpty)
                }
            }
        }
        
        
    }
}

struct EmptySubscription: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "link.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("暂无订阅")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("点击右上角 + 添加订阅")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
}


struct SubscriptionRow: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var clashService: ClashService
    @EnvironmentObject var vpnManager: VPNManager
    @EnvironmentObject var settings: Settings
    @Query(sort:\ClashProxy.createAt) private var proxyNodes:[ClashProxy]
    @State var subscription: Subscription
    @State var isUpdating: Bool = false
    @State var isDelete: Bool = false
    
    @State var clashNotRunAlert: Bool = false
    
    var body: some View {
        VStack() {
            
            HStack {
                Button(action: {
                    refreshSubscription()
                }) {
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isUpdating)
                .foregroundColor(.blue)
                .buttonStyle(.plain)
                .contentShape(Rectangle())
              
                
                Text(subscription.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                if let lastUpdate = subscription.lastUpdate {
                    Text(lastUpdate, style: .time)
                        .font(.footnote)
                        .foregroundColor(.primary)
                }else {
                    Text("未更新")
                        .font(.footnote)
                        .foregroundColor(.primary)
                }
                
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(subscription.isExpand ? 90 : 0)) // 旋转控制
                    .animation(.easeInOut(duration: 0.3), value: subscription.isExpand) // 动画
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(maxWidth: 35)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            subscription.isExpand.toggle()
                        }
                    }
                
            }
            .swipeActions(edge: .trailing) {
                Button() {
                    withAnimation {
                        isDelete.toggle()
                    }
                    
                }label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
                
            }
            .swipeActions(edge: .leading) {
                Button() {
                    refreshSubscription()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .tint(.blue)
                Button(){
                    if vpnManager.connect != .connected {
                        withAnimation{
                            clashNotRunAlert.toggle()
                        }
                    }else{
                        Task{
                            await subscriptionManager.testSubscription(proxyNodes)
                        }
                    }
                }label: {
                    Image(systemName: "timer")
                }
                .tint(.blue)
            }
        }
        .alert("请先开启代理", isPresented: $clashNotRunAlert){
            Button("确定"){
                withAnimation{
                    clashNotRunAlert.toggle()
                }
            }
        }
        .confirmationDialog(
            "确定要删除吗？",
            isPresented: $isDelete
        ) {
            Button("删除", role: .destructive) {
                withAnimation {
                    settings.delete(subscription)
                    var subIds = settings.subscriptions.map{$0.id}
                    var deletePorxyNodes = settings.proxyNodes.filter{$0.subId != nil && !subIds.contains($0.subId!)}
                    settings.delete(deletePorxyNodes)
                }
            }
        } message: {
            Text("删除后无法恢复")
        }
        
    }
    func refreshSubscription() {
       
        Task{
            isUpdating = true
            var proxys = await subscriptionManager.updateSubscription(subscription)
            if !proxys.isEmpty {
                settings.update(subscription){ sub in
                    sub.lastUpdate = Date()
                }
                settings.delete(proxyNodes.filter{$0.subId == subscription.id})
                proxys.forEach{$0.subId = subscription.id}
                
                settings.insert(proxys)
                
            }
            isUpdating = false
        }}
}

struct ProxyRow: View {
    @EnvironmentObject var subscriptionManager : SubscriptionManager
    @EnvironmentObject var vpnManager : VPNManager
    @EnvironmentObject var settings: Settings
    
    @State var proxy: ClashProxy
    @State var isDelete: Bool = false
    
    @State var clashNotRunAlert: Bool = false
    var body: some View {
        LazyVStack{
            HStack{
                if !settings.autoProxy {
                    Button(){
                        chooseThis()
                    }label: {
                        if settings.selectProxy == proxy.name {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .frame(maxWidth: 35)
                        } else {
                            Image(systemName: "checkmark")
                                .foregroundColor(.clear)
                                .font(.title2)
                                .frame(maxWidth: 35)
                        }
                        
                    }
                }
                VStack(alignment: .leading, spacing: 2){
                    Text(proxy.name)
                        .font(.footnote)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(proxy.type)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Spacer()
                Text(String(proxy.delay ?? 0) + "ms")
                    .font(.footnote)
                    .foregroundColor(.green)
                
            }
            .swipeActions(edge: .leading){
                Button(){
                    testThis()
                }label: {
                    Image(systemName: "timer")
                }
                .tint(.blue)
            }
            .swipeActions(edge: .trailing){
                Button(){
                    Task{
                        isDelete.toggle()
                    }
                }label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
        }
        .alert("请先开启代理", isPresented: $clashNotRunAlert){
            Button("确定"){
                showClashCheckAlert()
            }
        }
        .confirmationDialog(
            "确定要删除吗？",
            isPresented: $isDelete
        ) {
            Button("删除", role: .destructive) {
                deleteThis()
            }
        } message: {
            Text("删除后无法恢复")
        }
    }
    
    func showDeleteDialog(){
        withAnimation{
            isDelete.toggle()
        }
    }
    
    func showClashCheckAlert(){
        withAnimation{
            clashNotRunAlert.toggle()
        }
    }
    
    func chooseThis(){
        withAnimation{
            settings.selectProxy = proxy.name
        }
    }
    
    func deleteThis(){
        withAnimation {
            settings.delete(proxy)
        }
    }
    func testThis(){
        if vpnManager.connect != .connected {
            withAnimation{
                clashNotRunAlert.toggle()
            }
        }else{
            Task{
                await subscriptionManager.testProxy(proxy)
            }
        }
        
    }
}


#Preview {
    HomeView()
        .environmentObject(ClashService.share)
        .environmentObject(ClashManager.share)
        .environmentObject(VPNManager.share)
        .environmentObject(SubscriptionManager())
        .environmentObject(ClashAPIService.shared)
        .environmentObject(Settings.shared)
}
