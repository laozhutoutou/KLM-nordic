//
//  KLMMeshNetworkManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/8.
//

import Foundation
import nRFMeshProvision

class KLMMeshNetworkManager: NSObject {
    
    public weak var delegate: MeshNetworkDelegate?
    
    static let shared = KLMMeshNetworkManager()
    private override init(){}
}

extension KLMMeshNetworkManager: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        delegate?.meshNetworkManager(manager, didReceiveMessage: message, sentFrom: source, to: destination)
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        delegate?.meshNetworkManager(manager, didSendMessage: message, from: localElement, to: destination)
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        
        delegate?.meshNetworkManager(manager, failedToSendMessage: message, from: localElement, to: destination, error: error)
    }
}
