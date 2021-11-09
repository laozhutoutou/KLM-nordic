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
        ///配置数据转化成data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(network)
        ///data转化成字符串
        let newStr = String(data: data, encoding: String.Encoding.utf8)
        return newStr!
        
    }
    
    static func loadHome() -> KLMHomeModel? {
        
        if let fileURL = getHomeFile() {
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                
                let data = try! Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let model = try! decoder.decode(KLMHomeModel.self, from: data)
                return model
            }
        }
        
        return nil
    }
    
    static func saveHome(home: KLMHomeModel) {
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(home)
        let fileURL = getHomeFile()
        try! data.write(to: fileURL!)
    }
    
    private static func getHomeFile() -> URL? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return url?.appendingPathComponent("home")
    }
    
    static func upLoadMesh() {
        if let model = loadHome() {
            let manager = MeshNetworkManager.instance
            let data = manager.export(.full)
            let newStr = String(data: data, encoding: String.Encoding.utf8)
            ///提交到服务器
            KLMService.editMesh(id: model.id, meshName: nil, meshConfiguration: newStr) { response in
                KLMLog("配置数据提交成功")
            } failure: { error in
                
            }
        }
    }
}
