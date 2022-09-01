//
//  KLMTool.swift
//  KLM
//
//  Created by 朱雨 on 2022/4/22.
//

import Foundation
import KeychainAccess
import SwiftUI
import HandyJSON

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
    
    ///根据code获取国家名称
    static func getCountryNameByPhoneCode(phoneCode: String) -> String? {
        var name: String?
        let sortedName = Bundle.isChineseLanguage() ? "sortedNameCH" : "sortedNameEN"
        let path = Bundle.main.path(forResource: sortedName, ofType: "plist")
        let sortedNameDict = NSDictionary(contentsOfFile: path ?? "") as! [String: Any]
        for values in sortedNameDict.values {
            let nameLists: [String] = values as! [String]
            for string in nameLists {
                let array = string.components(separatedBy: "+")
                let countryName = array.first?.trimmingCharacters(in: CharacterSet.whitespaces)
                let code = array.last
                if code == phoneCode {
                    name = countryName
                    break
                }
            }
            if name != nil {
                break
            }
        }
        return name
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
    
    static public func checkBluetoothVersion(newestVersion: KLMVersion.KLMVersionData, bleversion: String, viewController: UIViewController, comfirm: @escaping () -> (), cancel: @escaping () -> (), noNeedUpdate: @escaping () -> ()) {
        
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
            vc.addAction(UIAlertAction.init(title: LANGLOC("Update"), style: .default, handler: { action in
                
                comfirm()
                
            }))
            vc.addAction(UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: { action in
                
                cancel()
            }))
            
            viewController.present(vc, animated: true)
        } else {
            
            noNeedUpdate()
        }
    }
}

extension KLMTool {
    
    ///JSON字符串转模型，使用该方法，假如字符串没有某个key,但是模型有，这个时候模型中的key值不会Nil，保留默认值。
    static func jsonToModel(_ jsonStr:String?,_ modelType:HandyJSON.Type) ->BaseModel {
        
        guard let jsonStr = isEmptyString(string: jsonStr) else {
            KLMLog("jsonoModel:字符串为空")
            return BaseModel()
        }

        return modelType.deserialize(from: jsonStr)  as! BaseModel
        
    }
}

class BaseModel: HandyJSON {
    required init() {}
    func mapping(mapper: HelpingMapper) {   //自定义解析规则，日期数字颜色，如果要指定解析格式，子类实现重写此方法即可

      }
}
