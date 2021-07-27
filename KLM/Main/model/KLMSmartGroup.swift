//
//  KLMSmartGroup.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/20.
//

import UIKit
import nRFMeshProvision

class KLMSmartGroup: NSObject {
    
    static let sharedInstacnce = KLMSmartGroup()
    private override init(){
        super.init()
        
    }
    
    typealias SuccessBlock = () -> Void
    typealias FailureBlock = (_ error: MessageError?) -> Void
    
    var successBlock: SuccessBlock!
    var failureBlock: FailureBlock!
    
    func sendMessage(_ parame: parameModel, toGroup group: Group,_ success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        
        MeshNetworkManager.instance.delegate = self
        
        successBlock = success
        failureBlock = failure
        
        var parameString = ""
        switch parame.dp {
        case .power,
             .colorTemp,
             .light,
             .cameraPower,
             .flash,
             .motionTime,
             .motionLight,
             .motionPower:
            let value = parame.value as! Int
            parameString = value.decimalTo2Hexadecimal()
        case .color,
             .recipe:
            parameString = parame.value as! String
        }
        
        let dpString = parame.dp.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("A", radix: 16) {
            let parameters = Data(hex: dpString) + parameString.data(using: .ascii)!
            let network = MeshNetworkManager.instance.meshNetwork!
            let models = network.models(subscribedTo: group)
            
            if let model = models.first {
                
                let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
                do {
                    
                    try MeshNetworkManager.instance.send(message, to: group, using: model.boundApplicationKeys.first!)
                    
                } catch {
                    
                    var err = MessageError()
                    err.message = error.localizedDescription
                    failure(err)
                    
                }
            }
        }
    }
    
    /// 给所有节点发消息
    /// - Parameters:
    ///   - parame: 参数
    ///   - success: success
    ///   - failure: failure
    func sendMessageToAllNodes(_ parame: parameModel,_ success: @escaping SuccessBlock, failure: @escaping FailureBlock)  {
        
        MeshNetworkManager.instance.delegate = self
        
        successBlock = success
        failureBlock = failure
        
        var parameString = ""
        switch parame.dp {
        case .power,
             .colorTemp,
             .light,
             .cameraPower,
             .flash,
             .motionTime,
             .motionLight,
             .motionPower:
            let value = parame.value as! Int
            parameString = value.decimalTo2Hexadecimal()
        case .color,
             .recipe:
            parameString = parame.value as! String
        }
        
        let dpString = parame.dp.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("A", radix: 16) {
            let parameters = Data(hex: dpString) + parameString.data(using: .ascii)!
            let network = MeshNetworkManager.instance.meshNetwork!
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner })
            guard !notConfiguredNodes.isEmpty else {
                
                //没有节点
                var err = MessageError()
                err.message = "no devices"
                failure(err)
                return
            }
            
            let model = KLMHomeManager.getModelFromNode(node: notConfiguredNodes.first!)!
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                //allNodes 为所有节点
                try  MeshNetworkManager.instance.send(message, to: MeshAddress.init(.allNodes), using: model.boundApplicationKeys.first!)
                
            } catch {
                
                var err = MessageError()
                err.message = error.localizedDescription
                failure(err)
                
            }
        }
    }
}

extension KLMSmartGroup: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        successBlock()
        
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        
        var err = MessageError()
        err.message = error.localizedDescription
        failureBlock(err)
    }
}
