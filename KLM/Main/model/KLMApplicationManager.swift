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
        
        //APP语言
        setupLanguage()
    
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
    
    private func setupSVHUD() {
        
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.setMinimumDismissTimeInterval(1.0)
    }
    
    private func setupKeyboard() {
        
        let manager =  IQKeyboardManager.shared
        manager.enable = true
        manager.shouldResignOnTouchOutside = true
        manager.shouldToolbarUsesTextFieldTintColor = true
        manager.toolbarDoneBarButtonItemText = LANGLOC("Done")
        ///不显示工具条
        manager.enableAutoToolbar = true
        manager.toolbarManageBehaviour = .byTag
        
    }
    
    private func setupLanguage() {
        
        ///定制APP只有英文
        if apptype == .targetSensetrack {
            
            DAConfig.userLanguage = "en"
        }
    }
    
    //单例
    static let sharedInstacnce = KLMApplicationManager()
    private init(){}
    
}
