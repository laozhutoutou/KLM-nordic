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
        
        MeshNetworkManager.instance.delegate = self
        
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
        
        MeshNetworkManager.instance.delegate = self
        
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
        
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        
        var err = MessageError()
        err.message = error.localizedDescription
        self.delegate?.messageManager(self, didHandleGroup: destination, error: err)
    }
}

struct MessageError: Error {
    
    var message: String?
    
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
    case checkVersion = 99
    case DFU = 100
    case PWM = 101
    case AllDp = 0xFF
}

struct parameModel {
    
    var dp: DPType = .power
    var value: Any = 0
    
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
