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
        KLMMeshNetworkManager.shared.delegate = self
        
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
                let err = MessageError()
                err.message = error.localizedDescription
                self.delegate?.smartNode(self, didfailure: err)
                
            }
        }
    }
    
    func readMessage(_ parame: parameModel, toNode node: Node) {
       
        currentNode = node
        KLMMeshNetworkManager.shared.delegate = self
        let model = KLMHomeManager.getModelFromNode(node: node)!
        let dpString = parame.dp!.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("1C", radix: 16) {
            let parameters = Data(hex: dpString)
            KLMLog("readParameter = \(parameters.hex)")
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
            
                try MeshNetworkManager.instance.send(message, to: model)
            } catch  {
                
                let err = MessageError()
                err.message = error.localizedDescription
                self.delegate?.smartNode(self, didfailure: err)
            }
        }
    }
    
    /// 删除节点
    func resetNode(node: Node) {
        
        currentNode = node
        KLMMeshNetworkManager.shared.delegate = self
        
        let message = ConfigNodeReset()
        do {
            try MeshNetworkManager.instance.send(message, to: node)
        } catch  {
            
            let err = MessageError()
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
                                        
                    ///不是当前节点的消息不处理
                    if source != currentNode?.unicastAddress {
                        KLMLog("别的节点回的消息")
                        return
                    }
                    
                    if status != 0 { ///返回错误

                        let err = MessageError()
                        err.code = Int(status)
                        err.dp = dp
                        err.message = LANGLOC("Data exception")
                        if status == 2 {
                            err.message = LANGLOC("Please turn the light on")
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
                        if status == 0xFD { //摄像头温度太高
                            err.message = LANGLOC("The temperature of camera is too high")
                        }
                        self.delegate?.smartNode(self, didfailure: err)
                        return
                    }
                    
                    if value.count == 0 { ///没有字节
                        let err = MessageError()
                        err.code = Int(status)
                        err.dp = dp
                        err.message = LANGLOC("Data exception")
                        self.delegate?.smartNode(self, didfailure: err)
                        return
                    }
                    
                    //返回成功也要卡住一些错误数据
                    switch dp {
                    case .cameraPic:
                        if value.count > 4 { ///数据有误
                            let err = MessageError()
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
                         .fenqu,
                         .encryption,
                         .powerSetting,
                         .customerCountingPower,
                         .customerCounting:
                        
                        response.value = Int(value.bytes[0])
                    case .color,
                         .cameraPic,
                         .checkVersion,
                         .hardwareInfo,
                         .audio,
                         .biaoding,
                         .controller,
                         .customerColor,
                         .deviceSetting:
                        
                        response.value = [UInt8](value)
                    case .recipe, //不处理结果
                         .colorTest,
                         .motion,
                         .PWM:
                        response.value = value
                    case .factoryTest,
                         .factoryTestResule:
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
        
        let err = MessageError()
        err.message = LANGLOC("Make sure the device is powered on and nearby.Otherwise,check if it is connected by others or out of order.")
        
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
        KLMMeshNetworkManager.shared.delegate = nil
        let err = MessageError()
        err.message = LANGLOC("Connection timed out.") + LANGLOC("Make sure the device is powered on and nearby.Otherwise,check if it is connected by others or out of order.")
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
             .powerSetting,
             .customerCountingPower,
             .motionPower:
            let value = parame.value as! Int
            parameString = value.decimalTo2Hexadecimal()
        case .color,
             .recipe,
             .PWM,
             .checkVersion,
             .factoryTest,
             .colorTest,
             .motion,
             .cameraPic,
             .hardwareInfo,
             .biaoding,
             .controller,
             .customerCounting,
             .customerColor,
             .factoryTestResule:
            parameString = parame.value as! String

        default:
            break
        }
        return parameString
    }
}

enum nodeDeviceType: String {
    case camera = "DD"
    case meta = "D0"
    case TwoCamera = "D1"
    case noCamera = "00"
    case qieXiang = "01"
    case RGBControl = "02"
    case Dali = "03"
}

extension Node {
    
    private static var Node_KEY = true
    
    var icon: String {
        switch deviceType {
        case .qieXiang:
            return "img_RCL"
        case .RGBControl:
            return "img_RGBW"
        case .Dali:
            return "img_DA"
        default:
            return "img_scene"
        }
    }
    
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
    
    var deviceType: nodeDeviceType {
        let index = uuid.uuidString[2,2]
        let type = nodeDeviceType.init(rawValue: index) ?? .camera
        return type
    }
    
    ///是控制器
    var isController: Bool {
        
        switch deviceType {
        case .qieXiang,
                .RGBControl,
                .Dali:
            return true
        default:
            return false
        }
    }
    
    ///是轨道灯
    var isTracklight: Bool {
        
        switch deviceType {
        case .camera,
                .meta,
                .TwoCamera,
                .noCamera:
            return true
        default:
            return false
        }
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
}

///给扩展增加存储属性
extension GattBearer {
    private static var Node_KEY = true
    var manufacturer: Data {
        get {
            return (objc_getAssociatedObject(self, &Self.Node_KEY) as? Data) ?? Data.init()
        }
        set {
            objc_setAssociatedObject(self, &Self.Node_KEY, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
    
    var nodeUUID: String {
        var uuid = ""
        if manufacturer.count >= 8 {
            let data: Data = manufacturer[2...7]
            uuid = data.hex
        }
        return uuid
    }
}


