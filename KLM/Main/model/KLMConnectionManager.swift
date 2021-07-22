//
//  KLMConnectionManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/19.
//

import UIKit
import nRFMeshProvision

protocol KLMConnectionManagerDelegate: AnyObject {
    
    func connectionManager(_ manager: KLMConnectionManager, didConnectProxyWithUUID identifier: UUID)
    
}

class KLMConnectionManager: NSObject {
    
    var discoveredPeripheral: DiscoveredPeripheral!
    weak var delegate:  KLMConnectionManagerDelegate?
    
    func scanAndConnectProxies() {
        
        //扫描1828已经配网的设备
        MeshNetworkManager.bearer.delegate = self
        MeshNetworkManager.bearer.close()
        //如果isopen是true,将无法再配置下一次
        MeshNetworkManager.bearer.isOpen = false
        DispatchQueue.main.asyncAfter(deadline: 1) {
            
            MeshNetworkManager.bearer.open()
            print("start scan node device")
        }
    }
    
    //初始化
    init(discoveredPeripheral: DiscoveredPeripheral){
        super.init()
        self.discoveredPeripheral = discoveredPeripheral
    }
}

extension KLMConnectionManager: BearerDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        print("connect node success1")
        let gatt: NetworkConnection = bearer as! NetworkConnection
        for bee in gatt.proxies {
            
            if bee.identifier == discoveredPeripheral.peripheral.identifier {
                print("connect node success2")
                //扫描并连接已经配网的设备
                self.delegate?.connectionManager(self, didConnectProxyWithUUID: bee.identifier)
                
                break
                
            }
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        
        
    }
}
