//
//  KLMApplicationManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import Foundation
import UIKit
import IQKeyboardManagerSwift

class KLMApplicationManager {
    
    func setupWindow(window : UIWindow) {
    
        setupSVHUD()
        
        //键盘处理
        setupKeyboard()
        
        ///交换点击按钮方法，可以给按钮设置点击间隔时间
        UIButton.initializeSendMethod()
        
        let token = KLMGetUserDefault("token")
        if token == nil {
            
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.enterLoginUI()
        } else {
            
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.enterMainUI()
        }
    }
    
    func setupSVHUD() {
        
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
    }
    
    private func setupKeyboard() {
        
        let manager =  IQKeyboardManager.shared
        manager.enable = true
        manager.shouldResignOnTouchOutside = true
        manager.shouldToolbarUsesTextFieldTintColor = true
        ///不显示工具条
        manager.enableAutoToolbar = true
        manager.toolbarManageBehaviour = .byTag
        
    }
    
    //单例
    static let sharedInstacnce = KLMApplicationManager()
    private init(){}
    
}
