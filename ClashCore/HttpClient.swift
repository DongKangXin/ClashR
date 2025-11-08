//
//  HttpClient.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/19.
//

import Foundation

/// 简洁的普通 HTTP 客户端（支持 POST）
@MainActor
class HTTPClient<T: Decodable> {
    private let baseURL: URL?
    private let defaultHeaders: [String: String]
    private let decoder: JSONDecoder
    private let secret: String?
    
    /// 初始化
    /// - Parameters:
    ///   - baseURL: 基础 URL（可选，用于相对路径）
    ///   - headers: 默认请求头
    ///   - secret: 认证密钥
    ///   - decoder: JSON 解码器
    init(
        baseURL: URL? = nil,
        headers: [String: String] = [:],
        secret: String? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = headers
        self.secret = secret
        self.decoder = decoder
    }
    
    // MARK: - GET 请求
    
    /// GET 请求
    /// - Parameter path: 路径（如果 baseURL 不为 nil，则为相对路径）
    func get(_ path: String = "") async throws -> T {
        let url = try buildURL(from: path)
        return try await request(url: url, method: "GET", body: nil)
    }
    
    // MARK: - POST 请求
    
    /// POST JSON 请求
    /// - Parameters:
    ///   - path: 路径
    ///   - body: 请求体（自动编码为 JSON）
    func post<U: Encodable> (_ path: String = "", body: U? = nil) async throws -> T {
        let url = try buildURL(from: path)
        let jsonData = body != nil ? try JSONEncoder().encode(body) : nil
        return try await request(url: url, method: "POST", body: jsonData)
    }
    
    /// POST 表单请求
    /// - Parameters:
    ///   - path: 路径
    ///   - parameters: 表单参数
    func postForm(_ path: String = "", parameters: [String: String]) async throws -> T {
        let url = try buildURL(from: path)
        let body = parameters.map { "\($0)=\($1)" }.joined(separator: "&")
        let bodyData = body.data(using: .utf8)
        return try await request(
            url: url,
            method: "POST",
            body: bodyData,
            additionalHeaders: ["Content-Type": "application/x-www-form-urlencoded"]
        )
    }
    
    // MARK: - 私有方法
    
    private func buildURL(from path: String) throws -> URL {
        if let baseURL = baseURL {
            return try baseURL.appendingPathComponent(path)
        } else if let url = URL(string: path) {
            return url
        } else {
            throw URLError(.badURL)
        }
    }
    
    private func request(
        url: URL,
        method: String,
        body: Data?,
        additionalHeaders: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        
        // 设置默认 headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 设置额外 headers
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 设置认证
        if let secret = secret {
            request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        }
        
        // 设置请求体
        if let body = body {
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            request.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 验证状态码
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw HTTPError.invalidStatusCode(httpResponse.statusCode)
        }
        
        // 解码数据
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Error
enum HTTPError: Error {
    case invalidStatusCode(Int)
}

extension HTTPError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidStatusCode(let code):
            return "HTTP 状态码错误: \(code)"
        }
    }
}
