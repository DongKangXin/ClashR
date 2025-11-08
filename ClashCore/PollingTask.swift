//
//  PollingTask.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/19.
//

import Foundation

func pollUntil<Value: Equatable>(
    every interval: TimeInterval = 1.0,
    maxAttempts: Int = 10,
    getValue: @escaping () -> Value?,
    targetValue: Value,
    onMatch: @escaping () -> Void,
    onTimeout: @escaping () -> Void
) {
    let timer = DispatchSource.makeTimerSource(queue: .main)
    var attempts = 0
    
    timer.schedule(deadline: .now(), repeating: interval)
    timer.setEventHandler {
        attempts += 1
        
        if let current = getValue(), current == targetValue {
            timer.cancel()
            onMatch()
            return
        }
        
        if attempts >= maxAttempts {
            timer.cancel()
            onTimeout()
        }
    }
    
    timer.resume()
}
