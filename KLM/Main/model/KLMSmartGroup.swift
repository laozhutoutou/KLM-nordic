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
    
    typealias SuccessBlock = (_ source: Address?) -> Void
    typealias FailureBlock = (_ error: MessageError?) -> Void
    
    var successBlock: SuccessBlock?
    var failureBlock: FailureBlock?
    
    ///分组 send
    func sendMessage(_ parame: parameModel, toGroup group: Group,_ success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        
        MeshNetworkManager.instance.delegate = self
        
        successBlock = success
        failureBlock = failure
        
        //蓝牙没开启
        do {
            try KLMConnectManager.checkBluetoothState()
            
        } catch {
            
            if let errr = error as? MessageError {
                failure(errr)
                return
            }
        }
        //一个设备都没连接
        if !MeshNetworkManager.bearer.isOpen {
            let err = MessageError()
            err.message = LANGLOC("deviceNearbyTip")
            failure(err)
            return
        }
        
        let parameString = KLMSmartNode.getParameHexString(parame)
        let dpString = parame.dp!.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("1A", radix: 16) {
            let parameters = Data(hex: dpString + parameString)
            KLMLog("parameter = \(parameters.hex)")
            let network = MeshNetworkManager.instance.meshNetwork!
            let models = network.models(subscribedTo: group)
            if let model = models.first {
                
                let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
                do {
                    
                    try MeshNetworkManager.instance.send(message, to: group, using: model.boundApplicationKeys.first!)
                    self.successBlock?(nil)
                    self.successBlock = nil
                    
                } catch {
                    
                    let err = MessageError()
                    err.message = error.localizedDescription
                    failure(err)
                    
                }
            } else {
                
                let err = MessageError()
                err.message = LANGLOC("noDevice")
                failure(err)
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
        
        do {
            try KLMConnectManager.checkBluetoothState()
            
        } catch {
            
            if let errr = error as? MessageError {
                failure(errr)
                return
            }
        }
        
        //一个设备都没连接
        if !MeshNetworkManager.bearer.isOpen {
            let err = MessageError()
            err.message = LANGLOC("deviceNearbyTip")
            failure(err)
            return
        }
        
        let parameString = KLMSmartNode.getParameHexString(parame)
        let dpString = parame.dp!.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("1A", radix: 16) {
            let parameters = Data(hex: dpString + parameString)
            KLMLog("parameter = \(parameters.hex)")
            
            let network = MeshNetworkManager.instance.meshNetwork!
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner })
            guard !notConfiguredNodes.isEmpty else {
                
                //没有节点
                let err = MessageError()
                err.message = LANGLOC("noDevice")
                failure(err)
                return
            }
            
            let model = KLMHomeManager.getModelFromNode(node: notConfiguredNodes.first!)!
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                //allNodes 为所有节点
                try  MeshNetworkManager.instance.send(message, to: MeshAddress.init(.allNodes), using: model.boundApplicationKeys.first!)
                self.successBlock?(nil)
                self.successBlock = nil
                
            } catch {
                
                var err = MessageError()
                err.message = error.localizedDescription
                failure(err)
                
            }
        }
    }
    
    ///所有节点 read
    func readMessageToAllNodes(_ parame: parameModel,_ success: @escaping SuccessBlock, failure: @escaping FailureBlock)  {
        
        MeshNetworkManager.instance.delegate = self
        
        successBlock = success
        failureBlock = failure
        
        do {
            try KLMConnectManager.checkBluetoothState()
            
        } catch {
            
            if let errr = error as? MessageError {
                failure(errr)
                return
            }
        }
        
        //一个设备都没连接
        if !MeshNetworkManager.bearer.isOpen {
            let err = MessageError()
            err.message = LANGLOC("deviceNearbyTip")
            failure(err)
            return
        }
        
        let dpString = parame.dp!.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("1C", radix: 16) {
            let parameters = Data(hex: dpString)
            KLMLog("readParameter = \(parameters.hex)")
            let network = MeshNetworkManager.instance.meshNetwork!
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner })
            guard !notConfiguredNodes.isEmpty else {
                
                //没有节点
                var err = MessageError()
                err.message = LANGLOC("noDevice")
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
    
    ///分组 read
    func readMessage(_ parame: parameModel, toGroup group: Group, _ success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        
        MeshNetworkManager.instance.delegate = self
        
        successBlock = success
        failureBlock = failure
        
        do {
            try KLMConnectManager.checkBluetoothState()

        } catch {

            if let errr = error as? MessageError {
                failure(errr)
                return
            }
        }

        //一个设备都没连接,  群组发送消息也可以发送出去，没报异常。所以要添加这个
        if !MeshNetworkManager.bearer.isOpen {
            var err = MessageError()
            err.message = LANGLOC("deviceNearbyTip")
            failure(err)
            return
        }
        
        let dpString = parame.dp!.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("1C", radix: 16) {
            let parameters = Data(hex: dpString)
            KLMLog("readParameter = \(parameters.hex)")
            let network = MeshNetworkManager.instance.meshNetwork!
            let models = network.models(subscribedTo: group)
            if let model = models.first {
                
                let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
                do {
                    
                    try MeshNetworkManager.instance.send(message, to: group, using: model.boundApplicationKeys.first!)
                    //开始定时
                    KLMMessageTime.sharedInstacnce.delegate = self
                    KLMMessageTime.sharedInstacnce.startTime()
                    
                } catch {
                    
                    var err = MessageError()
                    err.message = error.localizedDescription
                    failure(err)
                    
                }
            } else {
                
                var err = MessageError()
                err.message = LANGLOC("noDevice")
                err.code = -1
                failure(err)
            }
        }
    }
}

extension KLMSmartGroup: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        if manager.meshNetwork?.localProvisioner?.node?.unicastAddress != destination {
            KLMLog("别的手机发的消息")
            return
        }
        
        ///收到回复，停止计时
        KLMMessageTime.sharedInstacnce.stopTime()
        
        switch message {
        case let message as UnknownMessage://收发消息
            if let parameters = message.parameters {
                //如果是开关 "0101"
                KLMLog("messageResponse = \(parameters.hex)")
                
                if parameters.count >= 3 {
                    
                    self.successBlock?(source)
//                    self.successBlock = nil
                } 
            }
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        KLMLog("消息发送成功")
        
//        KLMMessageTime.sharedInstacnce.delegate = self
//        KLMMessageTime.sharedInstacnce.startTime()
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        
        ///失败停止计时
        KLMMessageTime.sharedInstacnce.stopTime()
        
        SVProgressHUD.dismiss()
        var err = MessageError()
        err.message = error.localizedDescription
        failureBlock?(err)
        failureBlock = nil
    }
}

extension KLMSmartGroup: KLMMessageTimeDelegate {
    
    func messageTimeDidTimeout(_ manager: KLMMessageTime) {
        
        ///超时后不再接收蓝牙消息
        MeshNetworkManager.instance.delegate = nil
        var err = MessageError()
        err.message = LANGLOC("Connection timed out.") + LANGLOC("deviceNearbyTip")
        failureBlock?(err)
        failureBlock = nil
    }
}
