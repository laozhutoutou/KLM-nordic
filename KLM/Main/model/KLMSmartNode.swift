//
//  KLMSmartNode.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/19.
//

import UIKit
import nRFMeshProvision

class KLMSmartNode: NSObject {
    
    static let sharedInstacnce = KLMSmartNode()
    private override init(){
        super.init()
//        MeshNetworkManager.instance.delegate = self
    }
    
    typealias SuccessBlock = (_ response: parameModel?) -> Void
    typealias FailureBlock = (_ error: MessageError?) -> Void
  
    var successBlock: SuccessBlock!
    var failureBlock: FailureBlock!
    
    func sendMessage(_ parame: parameModel, toNode node: Node,_ success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        //代理放这里
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
        //zhuzhu
        let model = KLMHomeManager.getModelFromNode(node: node)!
        //数据格式：比如，power dp 01 ,开 01 "0101"字符串转化成
        let dpString = parame.dp.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("A", radix: 16) {
            let parameters = Data(hex: dpString + parameString)
//            let parameters = Data(hex: "01010102")
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                try MeshNetworkManager.instance.send(message, to: model)
                
            } catch {
                var err = MessageError()
                err.message = error.localizedDescription
                failure(err)
                
            }
        }
    }
    
    func readMessage(node: Node, _ success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        
        successBlock = success
        failureBlock = failure
        
        let model = KLMHomeManager.getModelFromNode(node: node)!
        if let opCode = UInt8("C", radix: 16) {
            let parameters = Data(hex: "01010101")
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                try MeshNetworkManager.instance.send(message, to: model)
            } catch  {
                
                var err = MessageError()
                err.message = error.localizedDescription
                failure(err)
            }
        }
    }
}

extension KLMSmartNode: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        switch message {
        case let message as UnknownMessage:
            if let parameters = message.parameters {
                //如果是开关 "0101"
                KLMLog("messageResponse = \(parameters.hex)")
                
                if parameters.count >= 2 {
                    
                    var response = parameModel()
                    let dpData = parameters[0]
                    let value = parameters.suffix(from: 1).hex
                    response.value = value
                    switch dpData {
                    case 1:
                        response.dp = .power
                    case 2:
                        response.dp = .color
                    case 3:
                        response.dp = .colorTemp
                    case 4:
                        response.dp = .light
                    case 5:
                        response.dp = .recipe
                    case 6:
                        response.dp = .cameraPower
                    case 7:
                        response.dp = .flash
                    case 8:
                        response.dp = .motionTime
                    case 9:
                        response.dp = .motionLight
                    case 10:
                        response.dp = .motionPower
                    default:
                        break
                    }
                    
                    successBlock(response)
                    
                } else {
                    
                    successBlock(nil)
                }
                
            } else {
                
                successBlock(nil)
            }
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        
        var err = MessageError()
        err.message = error.localizedDescription
        failureBlock(err)
    }
}

