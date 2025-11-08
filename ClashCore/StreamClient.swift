import Foundation

/// 简洁的流式 HTTP 客户端

class StreamClient<T: Decodable> {
    private let url: URL
    private let decoder: JSONDecoder
    private let maxRetries: Int  // 新增：最大重试次数
    private var currentRetryCount = 0  // 新增：当前重试次数
    private var isCancelled = false  // 新增：取消标记
    
    private var session: URLSession?
    private var delegate: StreamDelegate<T>?
    
    /// 初始化
    /// - Parameters:
    ///   - url: 请求地址
    ///   - decoder: JSON 解码器（可选，默认使用标准解码器）
    ///   - maxRetries: 最大重试次数（默认 3 次）
    init(url: URL, decoder: JSONDecoder = JSONDecoder(), maxRetries: Int = 3) {
        self.url = url
        self.decoder = decoder
        self.maxRetries = maxRetries
    }
    
    /// 开始流式请求
    /// - Parameters:
    ///   - onEvent: 接收到事件时的回调
    ///   - onComplete: 请求完成时的回调
    /// - Returns: 取消任务的闭包
    func start(
        onEvent: @escaping (T) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) -> () -> Void {
        // 重置状态
        currentRetryCount = 0
        isCancelled = false
        
        // 定义启动函数
        func startStream() {
            let streamDelegate = StreamDelegate(
                decoder: decoder,
                onEvent: onEvent,
                onComplete: { [weak self] error in
                    guard let self = self else { return }
                    
                    // 检查是否需要重试
                    if let error = error,
                       !self.isCancelled,
                       self.currentRetryCount < self.maxRetries {
                        
                        self.currentRetryCount += 1
                        print("Stream connection failed, retry \(self.currentRetryCount)/\(self.maxRetries)...")
                        
                        // 延迟 2 秒后重试
                        Task {
                            try await Task.sleep(nanoseconds: 2_000_000_000)
                            if !self.isCancelled {
                                startStream()
                            }
                        }
                    } else {
                        // 不重试，直接完成
                        onComplete(error)
                    }
                }
            )
            
            let session = URLSession(configuration: .default, delegate: streamDelegate, delegateQueue: nil)
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 300
            
            let task = session.dataTask(with: request)
            task.resume()
            
            self.session = session
            self.delegate = streamDelegate
        }
        
        startStream()
        
        return { [weak self] in
            self?.isCancelled = true
            self?.session?.invalidateAndCancel()
        }
    }
    
    deinit {
        session?.invalidateAndCancel()
    }
}

// MARK: - Private Delegate
private class StreamDelegate<T: Decodable>: NSObject, URLSessionDataDelegate {
    private let decoder: JSONDecoder
    private let onEvent: (T) -> Void
    private let onComplete: (Error?) -> Void
    private var buffer = Data()
    
    init(
        decoder: JSONDecoder,
        onEvent: @escaping (T) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) {
        self.decoder = decoder
        self.onEvent = onEvent
        self.onComplete = onComplete
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        Task { @MainActor in
            // 🔧 修复：使用完整的 buffer 而不是只处理新数据
            let newBuffer = self.buffer + data
            guard let fullString = String(data: newBuffer, encoding: .utf8) else {
                self.buffer = newBuffer
                return
            }
            
            // 按行分割处理
            let lines = fullString.components(separatedBy: .newlines)
            var processedLength = 0
            
            for line in lines {
                if line.isEmpty {
                    continue
                }
            
                if line.hasPrefix("data: ") {
                    let jsonData = String(line.dropFirst(6))
                    do {
                        let data = try jsonData.data(using: .utf8).unwrap()
                        let object = try decoder.decode(T.self, from: data)
                        self.onEvent(object)
                        processedLength += line.utf8.count + 1 // +2 for "\n\n"
                    } catch {
                        print("解码错误: \(error)")
                    }
                }else {
                    do {
                        let data = try line.data(using: .utf8).unwrap()
                        let object = try decoder.decode(T.self, from: data)
                        self.onEvent(object)
                        processedLength += line.utf8.count + 1 // +2 for "\n\n"
                    } catch {
                        print("解码错误: \(error)")
                    }
                }
                processedLength += line.utf8.count + 1 // +1 for newline
            }
            
            // 更新缓冲区
            if processedLength < newBuffer.count {
                self.buffer = newBuffer.suffix(from: processedLength)
            } else {
                self.buffer = Data()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task { @MainActor in
            self.onComplete(error)
        }
    }
}

// MARK: - Helper
private extension Optional {
    func unwrap() throws -> Wrapped {
        guard let value = self else { throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "nil data")) }
        return value
    }
}
