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

var AppleStoreID: String {
    
    switch apptype {
    case .targetGN:
        return "1579633878"
    case .targetsGW:
        return "1618735485"
    case .test:
        return "1584589375"
    }
}

//分3个包
enum AppType {
    case targetGN //国内版
    case targetsGW //国外版
    case test //测试版
}

var apptype: AppType {
    
#if target_GN
    return AppType.targetGN
#elseif target_GW
    return AppType.targetsGW
#elseif target_Test
    return AppType.test
#endif
}

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
    let time = KLMLogManager.sharedInstacnce.logDateTime()
    if let dic: Dictionary = parameter as? Dictionary<String, Any> {
        let message: String = dic.jsonPrint()
        print("[\(time) \(fileName):line:\(lineNumber)]\n --\(message)\n")
        return
    }
    
    print("[\(time) \(fileName):line:\(lineNumber)]\n --\(parameter)\n")
    #else
    
    #endif
}
/*** 颜色***/
func rgba(_ r : CGFloat, _ g : CGFloat, _ b : CGFloat, _ a : CGFloat) -> UIColor {
    return UIColor(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: a)
}

func rgb(_ r : CGFloat, _ g : CGFloat, _ b : CGFloat) -> UIColor {
    return rgba(r, g, b, 1.0)
}

//APP导航栏颜色 UIColor.white
let navigationBarColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
//APP主题颜色 rgba(184, 23, 68, 1)
let appMainThemeColor = #colorLiteral(red: 0.7215686275, green: 0.09019607843, blue: 0.2666666667, alpha: 1)
//APP背景颜色 rgba(247, 247, 247, 1)
let appBackGroupColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
    
//版本信息
let KLM_SYSTEM_VERSION = Float(UIDevice.current.systemVersion)
let KLM_APP_NAME = Bundle.main.infoDictionary?["CFBundleDisplayName"]
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
func KLMShowError(_ error: MessageError?) {
    
    SVProgressHUD.showError(withStatus: error?.message)
    
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
    var message: String = error.userInfo["egMsg"] as! String
    if Bundle.isChineseLanguage() {
        message = error.userInfo["error"] as! String
    }
    SVProgressHUD.showError(withStatus: message)
}

///国内版
var baseUrl: String {
    switch apptype {
    case .targetGN,
         .test:
        return "https://light.kaiwaresz.com/"
    case .targetsGW:
        return "https://ai.kaiwaresz.com/"
    }
}

func KLMUrl(_ url: String) -> String {
    
    return baseUrl + url
}
