//
//  ClashCore.swift
//  ClashCore
//
//  Created by 董康鑫 on 2025/10/23.
//

import Foundation

class ClashCore {
    static let share = ClashCore()
    
    private lazy var darwinSender = DarwinNotificationSender.share
    
    private var trafficStreamClient: StreamClient<TrafficInfo>?
    
    var traffic: TrafficInfo?
    var lastStart: Date = Date()
    var trafficList: [TrafficInfo] = []
    
    /// 开始流量监控
    public func startTrafficMonitoring() {
        guard trafficStreamClient == nil else { return }
        
        guard let url = URL(string: "http://127.0.0.1:9090/traffic") else {
            return
        }
        trafficStreamClient = StreamClient<TrafficInfo>(url: url)
        _ = trafficStreamClient?.start(onEvent: {[weak self] traffic in
            guard self != nil  else {return}
            self?.traffic = traffic
            self?.trafficList.append(traffic)
            let lastStartTime = self?.lastStart.timeIntervalSince1970 ?? Double(0)
            if Date().timeIntervalSince1970 - lastStartTime > 1 {
                var up = 0
                var down = 0
                self?.trafficList.forEach{
                    up += $0.up
                    down += $0.down
                }
                self?.trafficList.removeAll()
                self?.lastStart = Date()
                ShareGroup.setUploadSpeed(up)
                ShareGroup.setDownloadSpeed(down)
                self?.darwinSender.postDarwinNotification(DarwinNotificationSender.speedNotify)
            }
        }, onComplete: {[weak self]  error in
            if let error = error {
            }
        })
    }
    //关闭流量监控
    func stopTrafficMonitoring(){
        guard trafficStreamClient != nil else { return }
        trafficStreamClient = nil
        
    }
    
}

/// 流量信息
struct TrafficInfo: Codable {
    let up: Int
    let down: Int
}
