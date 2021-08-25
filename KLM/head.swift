//
//  head.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit

//第三库
import SnapKit
import SnapKitExtend
import RxSwift
import RxCocoa
import nRFMeshProvision
import HandyJSON

/*** 常用 ***/
let KLMScreenW = UIScreen.main.bounds.size.width
let KLMScreenH = UIScreen.main.bounds.size.height
let KLMBounds = UIScreen.main.bounds

//导航栏等高度
let KLM_StatusBarHeight = UIApplication.shared.statusBarFrame.size.height //状态栏高度
let KLM_NavBarHeight = 44.0 //导航栏高度
let KLM_TopHeight = KLM_StatusBarHeight + CGFloat(KLM_NavBarHeight) //整个导航栏高度
let KLM_TabbarHeight = (KLM_StatusBarHeight>20 ? CGFloat(83) : CGFloat(49)) //底部tabbar高度
let KLM_BottomSafeAreaHeight = (KLM_StatusBarHeight>20 ? 34 : 0)

//keyWindow
let KLMKeyWindow = UIApplication.shared.keyWindow
    
//打印
func KLMLog<T>(_ parameter : T, file : String = #file, lineNumber : Int = #line)
{
    #if DEBUG
    
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):line:\(lineNumber)]\n --\(parameter)\n")
    
    #endif
}
/*** 颜色***/
func rgba(_ r : CGFloat, _ g : CGFloat, _ b : CGFloat, _ a : CGFloat) -> UIColor {
    return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
}

func rgb(_ r : CGFloat, _ g : CGFloat, _ b : CGFloat) -> UIColor {
    return rgba(r, g, b, 1.0)
}

//APP导航栏颜色
let navigationBarColor = UIColor.white
//APP主题颜色
let appMainThemeColor = rgba(184, 23, 68, 1)
//APP背景颜色
let appBackGroupColor = rgba(247, 247, 247, 1)

    
//版本信息
let KLM_SYSTEM_VERSION = Float(UIDevice.current.systemVersion)
let KLM_APP_NAME = Bundle.main.infoDictionary?["CFBundleName"]
let KLM_APP_VERSION = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
let KLM_APP_BUILD = Bundle.main.infoDictionary?["CFBundleVersion"]

/*** UserDefaults ***/
func KLMSetUserDefault(_ key : String, _ value : Any?) -> Void{
    
    UserDefaults.standard.setValue(value, forKey: key)
    UserDefaults.standard.synchronize()
    
}

func KLMGetUserDefault(_ key : String) -> Any? {
    
    return UserDefaults.standard.value(forKey: key)
}

//国际化
func LANGLOC(_ key : String) -> String{
    return NSLocalizedString(key, comment: "")
}

//rxswift
let disposeBag = DisposeBag()

//error HUD
func KLMShowError(_ error: Error?) {
    
    SVProgressHUD.showError(withStatus: error?.localizedDescription)
    
}

//是否是空字符串 ""和nil 返回false 
func isEmptyString(text: String?) -> (Bool, String) {
    
    guard let T = text else { return (true, "") }
    guard !T.isEmpty else {
        return (true, "")
    }
    return (false, T)
}

//是否有错误
func isError(_ error: Error?) -> Bool {
    
    if error == nil {
        
        return false
        
    } else {
        
        return true
    }
}

/// 显示http请求错误
/// - Parameter error: NSError
func KLMHttpShowError(_ error: NSError) {
    SVProgressHUD.dismiss()
    let message: String = error.userInfo["error"] as! String
    SVProgressHUD.showError(withStatus: message)
}

/// URL
let baseUrl = "http://8.135.16.88:9898/"

func KLMGetUrl(_ url: String) -> String {
    
    return baseUrl + url
}

func KLMPostUrl(_ url: String) -> String {
    
    return baseUrl + "api/auth/" + url
}
