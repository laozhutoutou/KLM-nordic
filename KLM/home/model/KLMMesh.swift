//
//  KLMMesh.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/5.
//

import Foundation
import nRFMeshProvision

class KLMMesh {
    
    static func createMesh() -> String {
        
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        //创建一个APP key
        let network = MeshNetwork.init(name: "Mesh Network")
        try! network.add(provisioner: provisioner)
        let newKey: Data! = Data.random128BitKey()
        do {
            try network.add(applicationKey: newKey, withIndex: 0, name: "new key")
        } catch  {
            print(error)
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(network)
        let newStr = String(data: data, encoding: String.Encoding.utf8)
        return newStr!
        
//        _ = MeshNetworkManager.instance.createNewMeshNetwork(withName: "Mesh Network", by: provisioner)
//        _ = MeshNetworkManager.instance.save()
        
        //创建一个APP key
//        if MeshNetworkManager.instance.meshNetwork!.applicationKeys.isEmpty {
//
//            let newKey: Data! = Data.random128BitKey()
//            let network = MeshNetworkManager.instance.meshNetwork!
//            do {
//                try network.add(applicationKey: newKey, withIndex: 0, name: "new key")
//            } catch  {
//                print(error)
//            }
//
//            _ =  MeshNetworkManager.instance.save()
//
//        }
        
    }
    
    
}
