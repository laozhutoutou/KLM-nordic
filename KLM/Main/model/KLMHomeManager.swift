//
//  KLMHomeManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/10.
//

import Foundation
import nRFMeshProvision

///sig bluetooth是没有这个的
let companyIdentifier: UInt16 = 0xff00

let KLMPhoneKey = "KLMPhoneKey"
let KLMPasswordKey = "KLMPasswordKey"

//控制类型
enum ControllType{
    case Device
    case Group
    case AllDevices
}

class KLMHomeManager {
    
    //主要用于控制设备
    var smartNode: Node? {
        
        didSet {
            self.controllType =  .Device
        }
    }
    
    //主要用于控制分组
    var smartGroup: Group? {
        
        didSet {
            self.controllType =  .Group
        }
    }
    //控制类型
    var controllType: ControllType?

    static var currentNode: Node {
        
        return  KLMHomeManager.sharedInstacnce.smartNode!
    }
    
    //主要用于控制设备
    static var currentModel: Model {

        return  KLMHomeManager.getModelFromNode(node: KLMHomeManager.currentNode)!
        
    }
    
    //主要用于控制分组
    static var currentGroup: Group {
        
        return  KLMHomeManager.sharedInstacnce.smartGroup!
    }
    
    ///网络状态
    enum NetworkStatus {
        case NetworkStatusOK
        case NetworkStatusNotReachable
    }
    var networkStatus: NetworkStatus = .NetworkStatusOK
    
    //单例
    static let sharedInstacnce = KLMHomeManager()
    private init(){}
}

extension KLMHomeManager {
    
    static func cachePhoneAndPassword(_ phone: String, _ password: String) {
        
        KLMSetUserDefault(KLMPhoneKey, phone)
        KLMSetUserDefault(KLMPasswordKey, password)
    }
    
    static func cacheWIFIMsg(SSID: String, password: String) {
        
        KLMSetUserDefault("SSID", SSID)
        KLMSetUserDefault("WIFIPassword", password)
    }
    
    static func getWIFIMsg() -> (SSID: String, password: String)? {
        
        let ssid = KLMGetUserDefault("SSID")
        let pass = KLMGetUserDefault("WIFIPassword")
        return (ssid, pass) as? (SSID: String, password: String)
        
    }
    
}

extension KLMHomeManager {
    
    /// 通过node获取model
    /// - Parameter node: node
    /// - Returns: model
    static func getModelFromNode(node: Node) -> Model? {
        
        let models = node.primaryElement!.models
        for M in models {
            if M.modelIdentifier == 2 && M.companyIdentifier == companyIdentifier {
                return M
            }
        }
        return nil
    }
    
    /// 通过model获取node
    /// - Parameter model: model
    /// - Returns: node
    static func getNodeFromModel(model: Model) -> Node? {
        
        return model.parentElement?.parentNode
    }
}

extension KLMHomeManager {
    
    static func showTipView() {
        
        if KLMGetUserDefault("showTime") != nil {
            return
        }
        
        ///弹出提示框
        let vc = UIAlertController.init(title: LANGLOC("Auto Mode"), message: LANGLOC("Auto Mode has been changed. The sensor on the light detects commodity automatically every 20 minutes by default. For test purpose, tap one time in a row on “Auto Mode” item to set time intervals with “Auto Mode” on. Time interval can be changed from 5 seconds to 60 seconds. Turn on the light again, the time interval will be reset to 20 minutes."), preferredStyle: .alert)
        vc.addAction(UIAlertAction.init(title: LANGLOC("Do not show"), style: .destructive, handler: { action in
            KLMSetUserDefault("showTime", 1)
        }))
        vc.addAction(UIAlertAction.init(title: LANGLOC("Confirm"), style: .default, handler: { action in
            
        }))
        if let label: UILabel = vc.view.value(forKeyPath: "_messageLabel") as? UILabel {
            
            label.textAlignment = .left
        }
        
        KLMKeyWindow?.rootViewController?.present(vc, animated: true, completion: nil)
    }
}
