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

//历史记录最大存储条数
let HistoryMaxCacheNum = 20

//控制类型
enum ControllType{
    case Device
    case Group
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
    
    /// 当前连接的节点
    static var currentConnectNode: Node? {
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            
            for node in notConfiguredNodes {
                if node.UUIDString == MeshNetworkManager.bearer.connectNode {
                    
                    return node
                }
            }
        }
        
        return nil
    }
    
    //单例
    static let sharedInstacnce = KLMHomeManager()
    private init(){}
}

extension KLMHomeManager {
    
    static func cachePhoneAndPassword(_ phone: String, _ password: String) {
        
        KLMSetUserDefault(KLMPhoneKey, phone)
        KLMSetUserDefault(KLMPasswordKey, password)
    }
    
}

extension KLMHomeManager {
    
    /// 通过node获取model
    /// - Parameter node: node
    /// - Returns: model
    static func getModelFromNode(node: Node) -> Model? {
        
        let models = node.primaryElement!.models
        for M in models {
            if M.modelIdentifier == 1 && M.companyIdentifier == companyIdentifier {
                return M
            }
        }
        return nil
    }
    
    /// 通过节点获取OTA model
    /// - Parameter node: node
    /// - Returns: OTA model
    static func getOTAModelFromNode(node: Node) -> Model? {
        
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
