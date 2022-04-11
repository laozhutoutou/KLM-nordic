//
//  KLMConnectManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/4/8.
//

import Foundation
import nRFMeshProvision

class KLMConnectManager {
    
    var success: (() -> Void)?
    var failure: (() -> Void)?
    
    func connectToNode(node: Node, success: @escaping () -> Void, failure: @escaping () -> Void) {
        
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
    
    //单例
    static let shared = KLMConnectManager()
    private init(){}
}

extension KLMConnectManager: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
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
