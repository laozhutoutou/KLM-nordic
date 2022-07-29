//
//  KLMConnectManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/4/8.
//

import Foundation
import nRFMeshProvision
import CoreBluetooth

class KLMConnectManager {
    
    let timer: KLMTimer = KLMTimer()
    
    //蓝牙连接状态
    var state: CBManagerState?
    
    var success: (() -> Void)?
    var failure: (() -> Void)?
    
    func connectToNode(node: Node, success: @escaping () -> Void, failure: @escaping () -> Void) {
        
        ///将node当做proxies first
//        if let bearer = MeshNetworkManager.bearer.proxies.first(where: {$0.nodeUUID == node.UUIDString}) {
//
//            MeshNetworkManager.bearer.use(proxy: bearer)
//            success()
//            return
//        }
        
        //检查是否composition
        if !node.isCompositionDataReceived {
            //对于未composition的进行配置
            SVProgressHUD.show(withStatus: "Composition")
            SVProgressHUD.setDefaultMaskType(.black)

            KLMSIGMeshManager.sharedInstacnce.delegate = self
            KLMSIGMeshManager.sharedInstacnce.getCompositionData(node: node)
            return
        }
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        self.success = success
        self.failure = failure
        
        let parame = parameModel(dp: .power)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: node)
        
    }
    
    func connectToGroup(group: Group, success: @escaping () -> Void, failure: @escaping () -> Void) {
        
        self.success = success
        self.failure = failure
    
        let parame = parameModel(dp: .power)
        KLMSmartGroup.sharedInstacnce.readMessage(parame, toGroup: group) {
            SVProgressHUD.dismiss()
            self.success?()
            self.success = nil
        } failure: { error in
            KLMShowError(error)
            self.failure?()
            self.failure = nil
        }
    }
    
    func connectToAllNodes(success: @escaping () -> Void, failure: @escaping () -> Void) {
        
        //一个设备都没连接,  群组发送消息也可以发送出去，没报异常。所以要添加这个
        if !MeshNetworkManager.bearer.isOpen {
            var err = MessageError()
            err.message = LANGLOC("deviceNearbyTip")
            KLMShowError(err)
            failure()
            return
        }
    
        success()
    }
    
    //单例
    static let shared = KLMConnectManager()
    private init(){}
}

extension KLMConnectManager {
    
    ///检查手机蓝牙状态
    static func checkBluetoothState() throws {
        
        var err = MessageError()
        switch KLMConnectManager.shared.state {
        case .poweredOff:
            ///弹出手机蓝牙提示框
            err.message = LANGLOC("Please power on the Bluetooth of your mobile phone")
            throw err
        case .unauthorized:
            ///弹出APP蓝牙授权提示
            err.message = LANGLOC("The application is not authorized to use the Bluetooth")
            throw err
        default:
            break
        }
    }
}

extension KLMConnectManager: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .power {
            self.success?()
            self.success = nil
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        
        KLMShowError(error)
        self.failure?()
        self.failure = nil
    }
}

extension KLMConnectManager: KLMSIGMeshManagerDelegate {
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node) {
        
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        
        SVProgressHUD.showSuccess(withStatus: "Please tap again")
        
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?){
        
        KLMShowError(error)
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didSendMessage message: MeshMessage) {
        

    }
}
