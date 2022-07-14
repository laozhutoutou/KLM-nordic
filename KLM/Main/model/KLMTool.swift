//
//  KLMTool.swift
//  KLM
//
//  Created by 朱雨 on 2022/4/22.
//

import Foundation
import KeychainAccess
import SwiftUI

class KLMTool {
    
    //字符串转模型
    static func getModelFromString<T>(_ type: T.Type, from string: String?) -> T? where T : Codable  {
        
        guard let data = string?.data(using: .utf8) else { return nil }
        let model = try? JSONDecoder().decode(T.self, from: data)
        return model
    }
    
    //获取设备的UUID，卸载APP也不会变化
    static let KEYCHAIN_SERVICE:String = "kinglumi.jmj.com"
    static let IMEI_KEY:String = "IMEI"
    static func getUUID() -> String {
        let keychain = Keychain(service: KEYCHAIN_SERVICE)
        var uuid:String = ""
        do {
            uuid = try keychain.get(IMEI_KEY) ?? ""
        }
        catch let error {
            print(error)
        }
        print("1111 \(uuid)")
        if uuid.isEmpty {
            uuid = UUID().uuidString
            do {
                try keychain.set(uuid, key: IMEI_KEY)
            }
            catch let error {
                print(error)
                uuid = ""
            }
        }
        return uuid
    }
    
    //获取设备的UUID，卸载APP会变化，适合现在使用。
    static func getAppUUID() -> String {
        return UIDevice.current.identifierForVendor!.uuidString
    }
}

extension UIView {
    
    ///获取view所在的控制器
    func currentViewController() -> UIViewController? {
        //1.通过响应者链关系，取得此视图的下一个响应者
        var n = next
        while n != nil {
            //2.判断响应者对象是否是视图控制器类型
            if n is UIViewController {
                //3.转换类型后 返回
                return n as? UIViewController
            }
            n = n?.next
        }
        return nil
    }
}

extension KLMTool {
    
    /// 判断字符串是否是空的，去掉前后空格
    /// - Parameter string: string
    /// - Returns: 去掉前后空格的字符串
    static func isEmptyString(string: String?) -> String? {
        guard let string = string else { return nil }
        //字符串前后空格去掉
        let tt = string.trimmingCharacters(in: .whitespaces)
        if tt.isEmpty {
            return nil
        }
        return tt
    }
}

extension KLMTool {
    
    //单独的字典（json）转模型
    static public func jsonToModel<T>(type:T.Type, json:Any) -> T? where T:Codable {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return nil
        }
        guard let model = try? JSONDecoder.init().decode(type, from: jsonData) else {
            return nil
        }
        return model
    }
    
    //json数组转模型数组
    static public func jsonToModel<T>(type:T.Type, array:[[String:Any]]) -> [T]? where T:Codable {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: array, options: []) else {
            return nil
        }
        guard let result = try? JSONDecoder.init().decode([T].self, from: jsonData) else {
            return nil
        }
        return result
    }
}

extension KLMTool {
    
    static public func checkBluetoothVersion(newestVersion: KLMVersion.KLMVersionData, bleversion: String, viewController: UIViewController, comfirm: @escaping () -> (), cancel: @escaping () -> ()) {
        
        //最新版本 -- 服务器查询
        let newVersion: String = newestVersion.fileVersion
        let value = bleversion.compare(newVersion)
        if value == .orderedAscending {//左操作数小于右操作数，需要升级
            
            ///更新消息
            var updateMsg: String = newestVersion.englishMessage
            if Bundle.isChineseLanguage() {///使用中文
                updateMsg =  newestVersion.updateMessage
            }
            
            ///弹出更新框
            let vc = UIAlertController.init(title: LANGLOC("Softwareupdate"), message: "V \(newVersion)\n\(updateMsg)", preferredStyle: .alert)
            vc.addAction(UIAlertAction.init(title: LANGLOC("Update"), style: .destructive, handler: { action in
                
                comfirm()
                
            }))
            if newestVersion.isForceUpdate == false { //强制更新
                
                vc.addAction(UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: { action in
                    
                    cancel()
                }))
            }
            
            viewController.present(vc, animated: true)
        }
    }
}
