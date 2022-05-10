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
        manager.shouldToolbarUsesTextFieldTintColor = true;
        manager.enableAutoToolbar = true;
        manager.toolbarManageBehaviour = .byTag
        
    }
    
    //单例
    static let sharedInstacnce = KLMApplicationManager()
    private init(){}
    
}
