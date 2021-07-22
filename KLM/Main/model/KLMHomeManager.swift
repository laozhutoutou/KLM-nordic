//
//  KLMHomeManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/10.
//

import Foundation
import nRFMeshProvision

let KLMPhoneKey = "KLMPhoneKey"
let KLMPasswordKey = "KLMPasswordKey"
let KLMHomeId = "KLMHomeId"
let KLMHistoryKey = "KLMHistoryKey"

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
    
    //单例
    static let sharedInstacnce = KLMHomeManager()
    private init(){}
}

extension KLMHomeManager {
    
    static func cachePhoneAndPassword(_ phone: String, _ password: String) {
        
        KLMSetUserDefault(KLMPhoneKey, phone)
        KLMSetUserDefault(KLMPasswordKey, password)
    }
    
    static func cacheHomeId(_ homeId: Int64) {
        
        KLMSetUserDefault(KLMHomeId, homeId)
    }
    
    static func getHomeId() -> Int64{
        
         return KLMGetUserDefault(KLMHomeId) as! Int64
    }
    
    static func deleteCache() {
        
        KLMSetUserDefault(KLMHomeId, nil)
        
    }
    
    static func cacheHistoryLists(list: [String]) {
        //最多存储20条记录
        var lists = list
        if lists.count > HistoryMaxCacheNum {
            
            lists.removeLast()
        }
        KLMSetUserDefault(KLMHistoryKey, lists)
        
    }
    
    static func getHistoryLists() -> [String] {
        
        return KLMGetUserDefault(KLMHistoryKey) as? [String] ?? [String]()
        
    }
    
    static func deleteHistoryCache() {
        
        KLMSetUserDefault(KLMHistoryKey, nil)
        
    }
}

extension KLMHomeManager {
    
    /// 通过node获取model
    /// - Parameter node: node
    /// - Returns: model
    static func getModelFromNode(node: Node) -> Model? {
        
        let models = node.primaryElement!.models
        for M in models {
            if M.modelIdentifier == 4 {
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
