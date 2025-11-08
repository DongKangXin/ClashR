//
//  FileUtils.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/20.
//
import Foundation

public class FileUtils {
    /// App Group 标识符
    static let appGroupIdentifier = "group.com.sakura.clash"
    
    /// 获取 App Group 容器中的 Documents 目录 URL
    private static var documentsDirectoryURL: URL? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("❌ Failed to get App Group container")
            return nil
        }
        return containerURL.appendingPathComponent("Documents", isDirectory: true)
    }
    
    /// 获取 App Group/Documents 下指定子路径的绝对 URL
    /// - Parameter subpath: 相对于 App Group/Documents 的路径（如 "rules/reject.txt"）
    /// - Returns: 完整文件 URL，失败返回 nil
    public static func absoluteURL(forSubpath subpath: String) -> URL? {
        guard let documentsURL = documentsDirectoryURL else { return nil }
        let absoluteURL = documentsURL.appendingPathComponent(subpath)
        print("📁 Absolute URL: \(absoluteURL.path)")
        return absoluteURL
    }
    
    /// 获取绝对路径字符串
    public static func absolutePath(forSubpath subpath: String) -> String? {
        return absoluteURL(forSubpath: subpath)?.path
    }
    
    /// 从 Bundle 复制文件到 App Group/Documents/subpath
    public static func copyFileFromBundle(
        fileName: String,
        toSubpath subpath: String,
        force: Bool = false
    ) -> URL? {
        let fileManager = FileManager.default
        
        guard let destinationURL = absoluteURL(forSubpath: subpath) else { return nil }
        
        // 确保 Documents 目录存在
        if let documentsURL = documentsDirectoryURL,
           !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
                print("✅ Created App Group/Documents directory")
            } catch {
                print("❌ Failed to create Documents in App Group: \(error)")
                return nil
            }
        }
        
        // 创建目标子目录
        let destinationDir = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationDir.path) {
            do {
                try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            } catch {
                print("❌ Failed to create subdirectory: \(error)")
                return nil
            }
        }
        
        // 检查源文件
        guard let sourceURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("❌ File '\(fileName)' not found in Bundle")
            return nil
        }
        
        let destinationExists = fileManager.fileExists(atPath: destinationURL.path)
        
        if destinationExists && !force {
            print("ℹ️ File exists, skipped (force=false).")
            return destinationURL
        }
        
        do {
            if destinationExists && force {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            let action = force ? "Overwrote" : "Copied"
            print("✅ \(action) '\(fileName)' to App Group/Documents/\(subpath)")
            return destinationURL
        } catch {
            print("❌ Copy failed: \(error)")
            return nil
        }
    }
    
    /// 写入内容到 App Group/Documents/subpath
    public static func writeContentToFile(
        subpath: String,
        content: String,
        force: Bool = true
    ) -> URL? {
        let fileManager = FileManager.default
        
        guard let destinationURL = absoluteURL(forSubpath: subpath) else { return nil }
        
        // 确保 Documents 存在
        if let documentsURL = documentsDirectoryURL,
           !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            } catch {
                print("❌ Failed to create Documents: \(error)")
                return nil
            }
        }
        
        let destinationDir = destinationURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: destinationDir.path) {
            do {
                try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            } catch {
                print("❌ Failed to create directory: \(error)")
                return nil
            }
        }
        
        if fileManager.fileExists(atPath: destinationURL.path) && !force {
            print("ℹ️ File exists, skipped.")
            return destinationURL
        }
        
        do {
            try content.write(to: destinationURL, atomically: true, encoding: .utf8)
            let action = fileManager.fileExists(atPath: destinationURL.path) && force ? "Overwrote" : "Created"
            print("✅ \(action) file at App Group/Documents/\(subpath)")
            return destinationURL
        } catch {
            print("❌ Write failed: \(error)")
            return nil
        }
    }
    
    /// 从 App Group/Documents/subpath 读取内容
    public static func readContentFromFile(subpath: String) -> String? {
        guard let fileURL = absoluteURL(forSubpath: subpath) else { return nil }
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("❌ File not found: \(fileURL.path)")
            return nil
        }
        
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            print("✅ Read file from App Group/Documents/\(subpath)")
            return content
        } catch {
            print("❌ Read failed: \(error)")
            return nil
        }
    }
}
