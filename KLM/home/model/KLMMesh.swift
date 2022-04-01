//
//  KLMMesh.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/5.
//

import Foundation
import nRFMeshProvision

class KLMMesh {
    
    //单例
    static let instacnce = KLMMesh()
    private init(){}
    
    static func createMesh() -> String {
        
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        //创建一个APP key
        let network = MeshNetworkManager().createNewMeshNetwork(withName: "Mesh Network", by: provisioner)
//        let network = MeshNetwork.init(name: "Mesh Network")
//        try! network.add(provisioner: provisioner)
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
        return KLMCache.getCache(KLMHome.KLMHomeModel.self, key: "home")
        
    }
    ///保存选择的家庭
    static func saveHome(home: KLMHome.KLMHomeModel?) {
        KLMCache.setCache(model: home, key: "home")
        
    }
    ///删除存储的家庭
    static func removeHome() {
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
            ///地址不能唯一
            changeProvisionerAddress()
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
    ///更改provisoner的 unicastAddress为  0x199A(allocatedUnicastRange) - 用户的ID
    private static func changeProvisionerAddress() {
        
        ///当前mesh管理员无需更改
        if isMeshManager() {
            
            return
        }
        //更改provisioner 的 unicastAddress
        let manager = MeshNetworkManager.instance
        let meshNetwork = manager.meshNetwork!
        let provisioner: Provisioner =  (meshNetwork.provisioners.first)!
        guard let user = KLMUser.getUserInfo() else { return }
        let address = 0x199A - user.id
        let newAddress: Address = Address.init(address)
        print(newAddress.asString())
        
        if let node = provisioner.node {
            let unicastAddresses = node.elements.map { $0.unicastAddress }
            manager.proxyFilter?.remove(addresses: unicastAddresses)
        }
        do {
            try meshNetwork.assign(unicastAddress: newAddress, for: provisioner)
            // Add the new addresses to the Proxy Filter.
            let unicastAddresses = provisioner.node!.elements.map { $0.unicastAddress }
            manager.proxyFilter?.add(addresses: unicastAddresses)
        } catch  {
            print(error)
        }
        
        if manager.save() {
            
            
        }
    }
    
    ///保存配置数据同时提交到服务器
    static func save() -> Bool {
        
        if MeshNetworkManager.instance.save() {
            
            if let model = KLMMesh.loadHome() {
                let manager = MeshNetworkManager.instance
                let data = manager.export(.full)
                let newStr = String(data: data, encoding: String.Encoding.utf8)
                ///提交到服务器
                KLMService.editMesh(id: model.id, meshName: nil, meshConfiguration: newStr) { response in
                    KLMLog("配置数据提交成功")
                    
                } failure: { error in
                    
                    KLMHttpShowError(error)
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
        ///清空用户数据
        KLMUser.removeUserInfo()
        ///清空本地存储的mesh数据
        (UIApplication.shared.delegate as! AppDelegate).createNewMeshNetwork()
    }
    ///是否有家庭
    static func isLoadMesh() -> Bool {
        
        return KLMMesh.loadHome() == nil ? false : true
    }
    ///是否是管理员
    static func isMeshManager() -> Bool{
        
        guard let currentHome = KLMMesh.loadHome() else { return false }
        return isMeshManager(meshAdminId: currentHome.adminId!)
        
    }
    ///是否是管理员
    static func isMeshManager(meshAdminId: Int) -> Bool{
        
        guard let user = KLMUser.getUserInfo() else { return false }
        if meshAdminId == user.id {
            return true
        }
        return false
    }
    
    ///是否可以修改mesh配置数据
    static func isCanEditMesh() -> Bool {
        
        if isLoadMesh() == false {
            SVProgressHUD.showInfo(withStatus: LANGLOC("CreateHomeTip"))
            return false
        }
        
        if isMeshManager() == false {
            SVProgressHUD.showInfo(withStatus: LANGLOC("admin_permissions_tips"))
            return false
        }
        
        return true
    }
}
