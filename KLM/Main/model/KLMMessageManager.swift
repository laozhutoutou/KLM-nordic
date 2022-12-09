//
//  KLMMessageManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/17.
//

import Foundation
import nRFMeshProvision

protocol KLMMessageManagerDelegate: AnyObject {
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?)
}

class KLMMessageManager: NSObject{
    
    weak var delegate:  KLMMessageManagerDelegate?
    
    /// 设备添加进分组
    /// - Parameters:
    ///   - node: 节点
    ///   - group: 组
    func addNodeToGroup(withNode node: Node, withGroup group: Group) {
        
        KLMMeshNetworkManager.shared.delegate = self
        
        let model = KLMHomeManager.getModelFromNode(node: node)!
        if let message: ConfigMessage =
            ConfigModelSubscriptionAdd(group: group, to: model){
            
            do {
                try MeshNetworkManager.instance.send(message, to: node)
                
            } catch  {
                var err = MessageError()
                err.message = error.localizedDescription
                self.delegate?.messageManager(self, didHandleGroup: node.unicastAddress, error: err)
            }
        }
    }
    
    /// 设备从分组移除
    /// - Parameters:
    ///   - node: 节点
    ///   - group: 组
    func deleteNodeToGroup(withNode node: Node, withGroup group: Group) {
        
        KLMMeshNetworkManager.shared.delegate = self
        
        let model = KLMHomeManager.getModelFromNode(node: node)
        if let message: ConfigMessage =
            ConfigModelSubscriptionDelete(group: group, from: model!) {
            
            do {
                try MeshNetworkManager.instance.send(message, to: node)
            } catch  {
                var err = MessageError()
                err.message = error.localizedDescription
                self.delegate?.messageManager(self, didHandleGroup: node.unicastAddress, error: err)
            }
            
        }
    }
    
    //单例
    static let sharedInstacnce = KLMMessageManager()
    private override init(){
        super.init()
        
    }
}

extension KLMMessageManager: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        
        
        switch message {
        case let status as ConfigModelSubscriptionStatus://设备添加或者删除组
            
            if status.status == .success {
                
                self.delegate?.messageManager(self, didHandleGroup: destination, error: nil)
            } else {
                
                var error = MessageError()
                error.message = status.message
                self.delegate?.messageManager(self, didHandleGroup: destination, error: error)
            }
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        KLMLog("消息发送成功")
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        SVProgressHUD.dismiss()
        let err = MessageError()
        err.message = error.localizedDescription
        self.delegate?.messageManager(self, didHandleGroup: destination, error: err)
    }
}

class BaseError: Error {
    var message: String?
}

class MessageError: BaseError {
    
    var code: Int?
    var dp: DPType?
}

enum DPType: Int {
    case power = 1
    case color = 2 //色盘
    case colorTemp = 3 //色温
    case light = 4 //亮度
    case recipe = 5 //配方
    case cameraPower = 6
    case flash = 7
    case motionTime = 8
    case motionLight = 9
    case motionPower = 10
    case colorTest = 11
    case cameraPic = 12 //下载摄像头图像
    case passengerFlowPower = 13 //客流统计开关
    case passengerFlow = 14 //客流统计数据
    case category = 15 //分类
    case brightness = 17 //亮度
    case motion = 18 //节能
    case factoryTest = 19
    case factoryTestResule = 20
    case hardwareInfo = 21
    case biaoding = 22 ///标定
    case fenqu = 0x17 ///分区
    case encryption = 0x18 ///加密
    case controller = 30 ///控制器
    case audio = 88 //语音播报
    case checkVersion = 99
    case DFU = 100
    case PWM = 101
    case deviceSetting = 0xFE
    case AllDp = 0xFF
}

enum opCodeType {
    case send ///发送消息 00DB00FF
    case read ///读取消息 00DD00FF
}
struct parameModel {
    
    var dp: DPType?
    var value: Any = 0
    var opCode: opCodeType = .send
}

struct RuntimeVendorMessage: VendorMessage {
    
    let opCode: UInt32
    let parameters: Data?
    
    var isSegmented: Bool = false
    var security: MeshMessageSecurity = .low
    
    init(opCode: UInt8, for model: Model, parameters: Data?) {
        self.opCode = (UInt32(0xC0 | opCode) << 16) | UInt32(model.companyIdentifier!.bigEndian)
        self.parameters = parameters
    }
    
    init?(parameters: Data) {
        // This init will never be used, as it's used for incoming messages.
        return nil
    }
}

protocol KLMMessageTimeDelegate: AnyObject {
    
    func messageTimeDidTimeout(_ manager: KLMMessageTime)
}

extension KLMMessageTimeDelegate {
    
    func messageTimeDidTimeout(_ manager: KLMMessageTime) {
        
    }
}

class KLMMessageTime {
    
    ///超时时间
    var messageTimeout: Int = 6
    
    ///当前秒
    var currentTime: Int = 0
    ///定时器
    var messageTimer: Timer?
    
    weak var delegate: KLMMessageTimeDelegate?
    
    static let sharedInstacnce = KLMMessageTime()
    private init(){}
    
    //开始计时
    func startTime() {
        
        stopTime()
        
        messageTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(UpdateTimer), userInfo: nil, repeats: true)
    }
    
    //停止计时
    func stopTime() {
        currentTime = 0
        if messageTimer != nil {
            messageTimer?.invalidate()
            messageTimer = nil
        }
    }
    
    @objc func UpdateTimer() {
        
        currentTime += 1
        if currentTime > messageTimeout {//超时
            stopTime() 
            self.delegate?.messageTimeDidTimeout(self)
        }
    }
}



