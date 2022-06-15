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
