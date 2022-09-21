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
    
    var currentNode: Node?
    
    static let sharedInstacnce = KLMSmartNode()
    private override init(){
        super.init()
        
    }
    
    weak var delegate: KLMSmartNodeDelegate?
    
    func sendMessage(_ parame: parameModel, toNode node: Node) {
        
        currentNode = node
        MeshNetworkManager.instance.delegate = self
        
        let parameString = KLMSmartNode.getParameHexString(parame)
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
       
        currentNode = node
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
        
        currentNode = node
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
                    
                    var response = parameModel()
                    if message.opCode.hex() == "00DD00FF" {
                        KLMLog("读到的消息是 = \(parameters.hex)")
                        response.opCode = .read
                    }
                    ///状态 0为成功  其他为失败
                    let status = parameters[0]
                    /// dp点
                    let dpData = parameters[1]
                    /// 数据
                    let value: Data = parameters.suffix(from: 2)
                    
                    let dp = DPType(rawValue: Int(dpData))
                    response.dp = dp
                    
                    //语音播报
                    if dp == .audio {
                        
                        if value.count >= 2 {
                            let secondIndex = Int(value.bytes[1])
                            KLMAudioManager.shared.startPlay(type: secondIndex)
                        }
                        return
                    }
                    
                    ///不是当前节点的消息不处理
                    if source != currentNode?.unicastAddress {
                        KLMLog("别的节点回的消息")
                        return
                    }
                    
                    if status != 0 { ///返回错误

                        var err = MessageError()
                        err.code = Int(status)
                        err.dp = dp
                        err.message = LANGLOC("Dataexception")
                        if status == 2 {
                            err.message = LANGLOC("turnOnLightTip")
                        }
                        if dp == .cameraPic && status == 1 {
                            err.message = LANGLOC("The light failed to connect to WiFi. Maybe the WiFi password is incorrect")
                        }
                        if status == 0xFF { //没有这个dp点
                            err.message = LANGLOC("The device do not support")
                        }
                        if status == 0xFE { //摄像头有问题
                            err.message = LANGLOC("Camera failure")
                        }
                        self.delegate?.smartNode(self, didfailure: err)
                        return
                    }
                    
                    //返回成功也要卡住一些错误数据
                    switch dp {
                    case .cameraPic:
                        if value.count > 4 { ///数据有误
                            var err = MessageError()
                            err.code = 1
                            err.dp = dp
                            err.message = LANGLOC("The device do not support")
                            self.delegate?.smartNode(self, didfailure: err)
                            return
                        }
                    default:
                        break
                    }
                    
                    switch response.dp {
                    case .power,
                         .colorTemp,
                         .light,
                         .cameraPower,
                         .flash,
                         .motionTime,
                         .motionLight,
                         .motionPower,
                         .category,
                         .brightness,
                         .passengerFlow:
                        
                        response.value = Int(value.bytes[0])
                    case .color,
                         .cameraPic,
                         .checkVersion,
                         .hardwareInfo,
                         .deviceSetting:
                        
                        response.value = [UInt8](value)
                    case .recipe, //不处理结果
                         .colorTest,
                         .motion,
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
//        var err = MessageError()
//        err.message = "Unknow message"
//        self.delegate?.smartNode(self, didfailure: err)
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        if let parameters = message.parameters {
            
            KLMLog("消息发送成功 = \(parameters.hex)")
            if parameters.count >= 1 {
                
                //开始计时
                KLMMessageTime.sharedInstacnce.delegate = self
                
                let dpData = parameters[0]
                let dp = DPType(rawValue: Int(dpData))
                if dp == .cameraPic {
                    KLMMessageTime.sharedInstacnce.messageTimeout = 20
                } else if dp == .power{
                    KLMMessageTime.sharedInstacnce.messageTimeout = 4
                } else {
                    KLMMessageTime.sharedInstacnce.messageTimeout = 6
                }
                KLMMessageTime.sharedInstacnce.startTime()
            }
        }
        
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
        err.message = LANGLOC("Connection timed out.") + LANGLOC("deviceNearbyTip")
        self.delegate?.smartNode(self, didfailure: err)
    }
}

extension KLMSmartNode {
    
    ///通过参数获取参数hex字符串
    static func getParameHexString(_ parame: parameModel) -> String {
        var parameString = ""
        switch parame.dp {
        case .power,
             .colorTemp,
             .light,
             .cameraPower,
             .flash,
             .motionTime,
             .motionLight,
             .category,
             .audio,
             .brightness,
             .motionPower:
            let value = parame.value as! Int
            parameString = value.decimalTo2Hexadecimal()
        case .color,
             .recipe,
             .PWM,
             .checkVersion,
             .DFU,
             .factoryTest,
             .colorTest,
             .motion,
             .cameraPic,
             .hardwareInfo,
             .factoryTestResule:
            parameString = parame.value as! String

        default:
            break
        }
        return parameString
    }
}

extension Node {
    
    private static var Node_KEY = true
    private static var Version_KEY = true
    
    /// 节点的名称
    var nodeName: String {
        
        return self.name ?? "Unknow name"
    }
    ///节点uuid对应的广播数据
    var nodeuuidString: String {
        
        let string = self.uuid.uuidString.replacingOccurrences(of: "-", with: "")
        let substring = string[4,12]
        return substring
    }
    
    ///没有摄像头
    var noCamera: Bool {
        let index = uuid.uuidString[2,2]
        if index == "00" {
            return true
        }
        return false
    }
    ///是否在线
    var isOnline: Bool {
        get {
            return (objc_getAssociatedObject(self, &Self.Node_KEY) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &Self.Node_KEY, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
     
    var version: String {
        get {
            return (objc_getAssociatedObject(self, &Self.Version_KEY) as? String) ?? ""
        }
        set {
            objc_setAssociatedObject(self, &Self.Version_KEY, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
}

///给扩展增加存储属性
extension GattBearer {
    private static var Node_KEY = true
    var manufacturer: String {
        get {
            return (objc_getAssociatedObject(self, &Self.Node_KEY) as? String) ?? ""
        }
        set {
            objc_setAssociatedObject(self, &Self.Node_KEY, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
    
    var nodeUUID: String {
        var uuid = ""
        if manufacturer.count >= 12 {
            uuid = manufacturer[0,12]
        }
        return uuid
    }
    
    var version: String {
        
        var version = ""
        if manufacturer.count == 16 {
            let first: Int = Int(nodeUUID[12,2])!
            let second: Int = Int(nodeUUID[14,1])!
            let third: Int = Int(nodeUUID[15,1])!
            version = "\(first).\(second).\(third)"
            KLMLog("设备版本：\(version)")
        }
        return version
    }
}
