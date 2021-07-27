//
//  KLMProvisionManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/19.
//

import UIKit
import nRFMeshProvision

protocol KLMProvisionManagerDelegate: AnyObject {
    
    func provisionManager(_ manager: KLMProvisionManager, didFailChange error: Error?)
    
    func provisionManagerNodeAddSuccess(_ manager: KLMProvisionManager)
}

class KLMProvisionManager: NSObject {
    
    private var provisioningManager: ProvisioningManager!
    var bearer: ProvisioningBearer!
    var discoveredPeripheral: DiscoveredPeripheral!
    weak var delegate:  KLMProvisionManagerDelegate?
    
    //单例
    init(discoveredPeripheral: DiscoveredPeripheral, bearer: ProvisioningBearer) {
        super.init()
        self.discoveredPeripheral = discoveredPeripheral
        self.bearer = bearer
        self.bearer.delegate = self
    }
}

extension KLMProvisionManager {
    
    func identify() {
        
        let manager = MeshNetworkManager.instance
        self.provisioningManager = try! manager.provision(unprovisionedDevice: self.discoveredPeripheral.device, over: self.bearer)
        self.provisioningManager.delegate = self
        self.provisioningManager.logger = MeshNetworkManager.instance.logger
        
        DispatchQueue.main.asyncAfter(deadline: 1) {
            
            do {
                try self.provisioningManager.identify(andAttractFor: 5)
            } catch {
                
                print("error")
                self.delegate?.provisionManager(self, didFailChange: error)
            }
        }
    }
}

extension KLMProvisionManager: ProvisioningDelegate {
    func authenticationActionRequired(_ action: AuthAction) {
        
    }
    
    func inputComplete() {
        
    }
    
    func provisioningState(of unprovisionedDevice: UnprovisionedDevice, didChangeTo state: ProvisioningState) {
        
        switch state {
        case .capabilitiesReceived(let capabilities)://identify完成
            
            print("identify success")
            
            //provision
            if provisioningManager.networkKey == nil {
                let network = MeshNetworkManager.instance.meshNetwork!
                let networkKey = try! network.add(networkKey: Data.random128BitKey(), name: "Primary Network Key")
                provisioningManager.networkKey = networkKey
            }
            
            do {
                try self.provisioningManager.provision(usingAlgorithm:       .fipsP256EllipticCurve,
                                                       publicKey:            .noOobPublicKey,
                                                       authenticationMethod: .noOob)
            } catch {
                
                print("error")
                
                self.delegate?.provisionManager(self, didFailChange: error)
        
            }
            
        case .complete://provison完成
            
            print("provision success")
            
            //关闭和未配网设备的连接
            self.bearer.close()
        
        case let .fail(error):
            
            self.bearer.close()
            self.delegate?.provisionManager(self, didFailChange: error)
            
        default:
            break
        }
    }
}

extension KLMProvisionManager: GattBearerDelegate {
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        
        guard case .complete = provisioningManager.state else {
            KLMShowError(error)
            
            return
        }
        //节点添加完成
        if MeshNetworkManager.instance.save() {
            
            print("node add success")
            
            DispatchQueue.main.asyncAfter(deadline: 1) {
                
                self.delegate?.provisionManagerNodeAddSuccess(self)
            }
            
        }
    }
    
    func bearerDidOpen(_ bearer: Bearer) {
        
        
    }
}
