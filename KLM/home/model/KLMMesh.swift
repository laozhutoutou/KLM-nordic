//
//  KLMMesh.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/5.
//

import Foundation
import nRFMeshProvision

class KLMMesh {
    
    ///当期家庭
    static var currentHome: KLMHome.KLMHomeModel?
    
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
    ///获取存储的家庭
    static func loadHome() -> KLMHome.KLMHomeModel? {
        currentHome = KLMCache.getCache(KLMHome.KLMHomeModel.self, key: "home")
        return currentHome
        
    }
    ///保存选择的家庭
    static func saveHome(home: KLMHome.KLMHomeModel) {
        currentHome = home
        KLMCache.setCache(model: home, key: "home")
        
    }
    ///删除存储的家庭
    static func removeHome() {
        currentHome = nil
        KLMCache.removeObject(key: "home")
    }
    
    ///加载本地缓存的mesh数据
    static func loadLocalMeshData () {
        
        var loaded = false
        do {
            loaded = try MeshNetworkManager.instance.load()
        } catch {
            print(error)
            // ignore
        }
        
        if loaded {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
        }
    }
    ///mesh数据写入本地
    static func loadHomeMeshData(meshConfiguration: String) {
        
        ///测试导入
        let manager = MeshNetworkManager.instance
        do {
            let data = meshConfiguration.data(using: String.Encoding.utf8)
            _ = try manager.import(from: data!)
            saveAndReload()
        } catch {

        }
    }
    
    private static func saveAndReload() {
        
        let manager = MeshNetworkManager.instance
        if manager.save() {
            
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
                
            }
        }
    }
    
    ///保存配置数据同时提交到服务器
    static func save() -> Bool {
        
        if MeshNetworkManager.instance.save() {
            
            if let model = currentHome {
                let manager = MeshNetworkManager.instance
                let data = manager.export(.full)
                let newStr = String(data: data, encoding: String.Encoding.utf8)
                ///提交到服务器
                KLMService.editMesh(id: model.id, meshName: nil, meshConfiguration: newStr) { response in
                    KLMLog("配置数据提交成功")
                    
                } failure: { error in
                    
                }
            }
            return true
        }
        return false
    }
    
}

extension KLMMesh {
    
    static func logout() {
        
        ///token清空
        KLMSetUserDefault("token", nil)
        ///清空家庭数据
        self.removeHome()
        
        (UIApplication.shared.delegate as! AppDelegate).createNewMeshNetwork()
    }
    
    static func isLoadMesh() -> Bool {
        
        return currentHome == nil ? false : true
    }
    
    static func isMeshManager() {
        
        
    }
}
