//
//  KLMSmartNode.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/19.
//

import UIKit
import nRFMeshProvision

protocol KLMSmartNodeDelegate: AnyObject {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?)
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode)
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?)
}

extension KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?){
        
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?){
        
    }
}

class KLMSmartNode: NSObject {
    
    static let sharedInstacnce = KLMSmartNode()
    private override init(){
        super.init()
        
    }
    
    weak var delegate: KLMSmartNodeDelegate?
    
    func sendMessage(_ parame: parameModel, toNode node: Node) {
        
        MeshNetworkManager.instance.delegate = self
        
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
             .recipe,
             .colorTest,
             .PWM,
             .checkVersion,
             .DFU,
             .factoryTest,
             .factoryTestResule:
            parameString = parame.value as! String
        default:
            break
        }
        
        let model = KLMHomeManager.getModelFromNode(node: node)!
        //数据格式：比如，power dp 01 ,开 01 "0101"字符串转化成
        let dpString = parame.dp.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("A", radix: 16) {
            let parameters = Data(hex: dpString + parameString)
            KLMLog("parameter = \(parameters.hex)")
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
                
            } catch {
                var err = MessageError()
                err.message = "Connection failed"
                self.delegate?.smartNode(self, didfailure: err)
                
            }
        }
    }
    
    func readMessage(_ parame: parameModel, toNode node: Node) {
        
        MeshNetworkManager.instance.delegate = self
        
        let model = KLMHomeManager.getModelFromNode(node: node)!
        let dpString = parame.dp.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("C", radix: 16) {
            let parameters = Data(hex: dpString)
            KLMLog("parameter = \(parameters.hex)")
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
            } catch  {
                
                var err = MessageError()
                err.message = "Connection failed"
                self.delegate?.smartNode(self, didfailure: err)
            }
        }
    }
    
    /// 删除节点
    func resetNode(node: Node) {
        
        MeshNetworkManager.instance.delegate = self
        
        let message = ConfigNodeReset()
        do {
            try MeshNetworkManager.instance.send(message, to: node)
        } catch  {
            
            var err = MessageError()
            err.message = error.localizedDescription
            self.delegate?.smartNode(self, didfailure: err)
        }
    }
}

extension KLMSmartNode: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        ///收到回复，停止计时
        KLMMessageTime.sharedInstacnce.stopTime()
        
        switch message {
        case let message as UnknownMessage://收发消息
            if let parameters = message.parameters {
                //如果是开关 "0101"
                KLMLog("messageResponse = \(parameters.hex)")
                
                if parameters.count >= 2 {
                    
                    var response = parameModel()
                    let dpData = parameters[0]
                    let valueHex = parameters.suffix(from: 1).hex
                    switch dpData {
                    case 1:
                        
                        response.dp = .power
                        response.value = Int(valueHex.hexadecimalToDecimal()) as Any
                    case 2:
                        response.dp = .color
                        
                        response.value = valueHex
                    case 3:
                        
                        response.dp = .colorTemp
                        response.value = Int(valueHex.hexadecimalToDecimal()) as Any
                    case 4:
                        
                        response.dp = .light
                        response.value = Int(valueHex.hexadecimalToDecimal()) as Any
                    case 5:
                        response.dp = .recipe
                        
                        response.value = valueHex
                    case 6:
                        
                        response.dp = .cameraPower
                        response.value = Int(valueHex.hexadecimalToDecimal()) as Any
                    case 7:
                        
                        response.dp = .flash
                        response.value = Int(valueHex.hexadecimalToDecimal()) as Any
                    case 8:
                        
                        response.dp = .motionTime
                        response.value = Int(valueHex.hexadecimalToDecimal()) as Any
                    case 9:
                        
                        response.dp = .motionLight
                        response.value = Int(valueHex.hexadecimalToDecimal()) as Any
                    case 10:
                        
                        response.dp = .motionPower
                        response.value = Int(valueHex.hexadecimalToDecimal()) as Any
                    case 12:
                        response.dp = .cameraPic
                        let data = Data(hex: valueHex)
                        response.value = data
                    case 19:
                        response.dp = .factoryTest
                        response.value = valueHex
                    case 20:
                        response.dp = .factoryTestResule
                        response.value = valueHex
                    case 99:
                        response.dp = .checkVersion
                        response.value = valueHex
                    case 100:
                        response.dp = .DFU
                        response.value = valueHex
                    case 101:
                        
                        response.dp = .PWM
                        response.value = valueHex
                    default:
                        break
                    }
                    
                    self.delegate?.smartNode(self, didReceiveVendorMessage: response)
                    
                }
                
            }
        case is ConfigNodeResetStatus:
            self.delegate?.smartNodeDidResetNode(self)
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        if let parameters = message.parameters {
            
            KLMLog("消息发送成功 = \(parameters.hex)")
            
        }
           
        //开始计时
        KLMMessageTime.sharedInstacnce.startTime()
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        ///失败停止计时
        KLMMessageTime.sharedInstacnce.stopTime()
        
        SVProgressHUD.dismiss()
        var err = MessageError()
        err.message = error.localizedDescription
        self.delegate?.smartNode(self, didfailure: err)
    }
}

extension Node {
    
    /// 节点的名称
    var nodeName: String {
        
        return self.name ?? "Unknow name"
    }
    
    /// uuid 前面6个字节
    var UUIDString: String {
        
        let string = self.uuid.uuidString.replacingOccurrences(of: "-", with: "")
        let substring = string.substring(to: 12)
        return substring
    }
    
}
