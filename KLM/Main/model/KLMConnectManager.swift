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
    
    private lazy var timer: KLMTimer = {
        let timer = KLMTimer()
        timer.delegate = self
        return timer
    }()
    
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
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        self.success = success
        self.failure = failure
        
        //检查是否composition
        if !node.isCompositionDataReceived {
            //对于未composition的进行配置
            SVProgressHUD.show(withStatus: "Composition")
            SVProgressHUD.setDefaultMaskType(.black)
            KLMLog("Composition")
            timer.startTimer(timeOut: 10)
            KLMSIGMeshManager.sharedInstacnce.delegate = self
            KLMSIGMeshManager.sharedInstacnce.getCompositionData(node: node)
            return
        }
        
        //检查node是否绑定appkey
        if node.applicationKeys.isEmpty {
            
            SVProgressHUD.show(withStatus: "Add app key to node")
            SVProgressHUD.setDefaultMaskType(.black)
            KLMLog("Add app key to node")
            timer.startTimer(timeOut: 10)
            KLMSIGMeshManager.sharedInstacnce.delegate = self
            KLMSIGMeshManager.sharedInstacnce.addAppkeyToNode(node: node)
            return
        }
        
        //检查是否model绑定appkey
        if let model = KLMHomeManager.getModelFromNode(node: node), model.boundApplicationKeys.isEmpty {
            
            SVProgressHUD.show(withStatus: "Add app key to model")
            SVProgressHUD.setDefaultMaskType(.black)
            KLMLog("Add app key to model")
            timer.startTimer(timeOut: 10)
            KLMSIGMeshManager.sharedInstacnce.delegate = self
            KLMSIGMeshManager.sharedInstacnce.addAppkeyToModel(node: node)
            return
        }
        let parame = parameModel(dp: .power)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: node)
    }
    
    func connectToGroup(group: Group, success: @escaping () -> Void, failure: @escaping () -> Void) {
        
        self.success = success
        self.failure = failure
    
        let parame = parameModel(dp: .power)
        KLMSmartGroup.sharedInstacnce.readMessage(parame, toGroup: group) {source in
            SVProgressHUD.dismiss()
            self.onSuccess()
        } failure: { error in
            KLMShowError(error)
            self.onFailure()
        }
    }
    
    func connectToAllNodes(success: @escaping () -> Void, failure: @escaping () -> Void) {
        
        self.success = success
        self.failure = failure
        
        //一个设备都没连接,群组发送消息也可以发送出去，没报异常。所以要添加这个
        if !MeshNetworkManager.bearer.isOpen {
            var err = MessageError()
            err.message = LANGLOC("deviceNearbyTip")
            KLMShowError(err)
            self.onFailure()
            return
        }
    
        self.onSuccess()
    }
    
    private func onSuccess() {
        
        self.success?()
        self.success = nil
        self.failure = nil
    }
    
    private func onFailure() {
        
        self.failure?()
        self.failure = nil
        self.success = nil
    }
    
    //单例
    static let shared = KLMConnectManager()
    private init(){}
}

extension KLMConnectManager {
    
    ///检查手机蓝牙状态
    static func checkBluetoothState() throws {
        
        let err = MessageError()
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
            self.onSuccess()
            
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        
        KLMShowError(error)
        self.onFailure()
    }
}

extension KLMConnectManager: KLMSIGMeshManagerDelegate {
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node) {
        
        timer.stopTimer()
        
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        
        self.onSuccess()
        
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?){
        
        timer.stopTimer()
        KLMShowError(error)
        self.onFailure()
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didSendMessage message: MeshMessage) {
        

    }
}

extension KLMConnectManager: KLMTimerDelegate {
    
    func timeDidTimeout(_ timer: KLMTimer) {
        //提示错误
        SVProgressHUD.showInfo(withStatus: "Composition or Appkey bound timed out")
        self.onFailure()
    }
}
