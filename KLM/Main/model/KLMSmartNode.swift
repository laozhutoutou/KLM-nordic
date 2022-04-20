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
        let dpString = parame.dp!.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("1A", radix: 16) {
            let parameters = Data(hex: dpString + parameString)
            KLMLog("parameter = \(parameters.hex)")
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
                
            } catch {
                var err = MessageError()
                err.message = error.localizedDescription
                self.delegate?.smartNode(self, didfailure: err)
                
            }
        }
    }
    
    func readMessage(_ parame: parameModel, toNode node: Node) {
        
        MeshNetworkManager.instance.delegate = self
        
        let model = KLMHomeManager.getModelFromNode(node: node)!
        let dpString = parame.dp!.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("1C", radix: 16) {
            let parameters = Data(hex: dpString)
            KLMLog("readParameter = \(parameters.hex)")
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
            } catch  {
                
                var err = MessageError()
                err.message = error.localizedDescription
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
                
                if parameters.count >= 3 {
                    
                    var response = parameModel()
                        
                    ///有error
                    let status = parameters[0]
                    let dpData = parameters[1]
                    let value: Data = parameters.suffix(from: 2)
                    
                    let dp = DPType(rawValue: Int(dpData))
                    if status != 0 { ///返回错误

                        var err = MessageError()
                        err.code = Int(status)
                        err.dp = dp
                        err.message = LANGLOC("Dataexception")
    
                        if status == 2 {
                            err.message = LANGLOC("turnOnLightTip")
                        }
                        self.delegate?.smartNode(self, didfailure: err)

                        return
                    }
                    
                    response.dp = dp
                    
                    switch response.dp {
                    case .power,
                         .colorTemp,
                         .light,
                         .cameraPower,
                         .flash,
                         .motionTime,
                         .motionLight,
                         .motionPower,
                         .passengerFlow:
                        
                        response.value = Int(value.bytes[0])
                    case .color,
                         .cameraPic,
                         .checkVersion,
                         .deviceSetting:
                        
                        response.value = [UInt8](value)
                    case .recipe,
                         .PWM:
                        response.value = value
                    case .factoryTest,
                         .factoryTestResule,
                         .DFU:
                        response.value = value.hex

                    default:
                        break
                    }
                    
                    self.delegate?.smartNode(self, didReceiveVendorMessage: response)
                    return
                }
                
            }
        case is ConfigNodeResetStatus:
            self.delegate?.smartNodeDidResetNode(self)
            return
        default:
            break
        }
        
        //返回错误
        var err = MessageError()
        err.message = "Unknow message"
        self.delegate?.smartNode(self, didfailure: err)
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        if let parameters = message.parameters {
            
            KLMLog("消息发送成功 = \(parameters.hex)")
            
        }
           
        //开始计时
        KLMMessageTime.sharedInstacnce.delegate = self
        KLMMessageTime.sharedInstacnce.startTime()
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        ///失败停止计时
        KLMMessageTime.sharedInstacnce.stopTime()
        SVProgressHUD.dismiss()
        
        var err = MessageError()
        err.message = LANGLOC("deviceNearbyTip")
        
        do {
            try KLMConnectManager.checkBluetoothState()
            
        } catch {
            
            if let errr = error as? MessageError {
                err.message = errr.message
            }
        }
         
        self.delegate?.smartNode(self, didfailure: err)
    }
}

extension KLMSmartNode: KLMMessageTimeDelegate {
    
    func messageTimeDidTimeout(_ manager: KLMMessageTime) {
        
        ///超时后不再接收蓝牙消息
        MeshNetworkManager.instance.delegate = nil
        var err = MessageError()
        err.message = LANGLOC("ConnectTimeoutTip")
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
