//
//  GlobalAlertManager.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/25.
//


import UIKit

class GlobalAlertManager {
    static let shared = GlobalAlertManager()
    private var alertWindow: UIWindow?
    
    func showAlert(
        title: String,
        message: String,
        actions: [UIAlertAction] = [],
        completion: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            // ✅ 设置文字样式
            self.styleAlertController(alertController)
            
            if actions.isEmpty {
                alertController.addAction(UIAlertAction(title: "确定", style: .default))
            } else {
                for action in actions {
                    alertController.addAction(action)
                }
            }
            
            self.present(alertController, completion: completion)
        }
    }
    
    // ✅ iOS 风格美化
    private func styleAlertController(_ alertController: UIAlertController) {
        // 标题样式
        if let title = alertController.title {
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            alertController.setValue(
                NSAttributedString(string: title, attributes: titleAttributes),
                forKey: "attributedTitle"
            )
        }
        
        // 消息样式
        if let message = alertController.message {
            let messageAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            alertController.setValue(
                NSAttributedString(string: message, attributes: messageAttributes),
                forKey: "attributedMessage"
            )
        }
    }
    
    private func present(_ alertController: UIAlertController, completion: (() -> Void)?) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        let originalKeyWindow = windowScene.windows.first { $0.isKeyWindow }
        
        // 创建新 window
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        let alertViewController = UIViewController()
        alertViewController.view.backgroundColor = .clear
        
        alertWindow.rootViewController = alertViewController
        alertWindow.windowScene = windowScene
        alertWindow.windowLevel = .alert + 1
        alertWindow.makeKeyAndVisible()
        
        self.alertWindow = alertWindow
        
        alertViewController.present(alertController, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.waitForAlertDismiss(alertWindow, originalKeyWindow, completion)
        }
    }
    
    private func waitForAlertDismiss(
        _ alertWindow: UIWindow,
        _ originalKeyWindow: UIWindow?,
        _ completion: (() -> Void)?
    ) {
        if alertWindow.rootViewController?.presentedViewController != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.waitForAlertDismiss(alertWindow, originalKeyWindow, completion)
            }
        } else {
            originalKeyWindow?.makeKeyAndVisible()
            self.alertWindow = nil
            completion?()
        }
    }
}
