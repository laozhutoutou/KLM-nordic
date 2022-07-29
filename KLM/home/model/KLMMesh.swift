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
        KLMCache.setCache(model: home, key: "home\(home!.id)")
    }
    ///删除存储的家庭
    static func removeHome() {
        KLMCache.removeObject(key: "home")
    }
    ///根据meshid获取本地保存的数据
    static func getHome(homeId: Int) -> KLMHome.KLMHomeModel? {
        return KLMCache.getCache(KLMHome.KLMHomeModel.self, key: "home\(homeId)")
    }
    
    ///加载本地缓存的mesh数据
//    static func loadLocalMeshData () {
//        
//        var loaded = false
//        do {
//            loaded = try MeshNetworkManager.instance.load()
//        } catch {
//            print(error)
//            // ignore
//        }
//        
//        if loaded {
//            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
//        }
//    }
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
            print(error)
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
    ///更改provisoner的 unicastAddress
    private static func changeProvisionerAddress() {
        
        //从服务器获取地址
        let model = KLMMesh.loadHome()!
        KLMService.getMeshProvisonerAddress(meshId: model.id, uuid: KLMTool.getAppUUID()) { response in
            guard var address = response as? Int else { return }
            
            let manager = MeshNetworkManager.instance
            let meshNetwork = manager.meshNetwork!
            let provisioner: Provisioner =  (meshNetwork.provisioners.first)!
            address = 0x199A - address
            if apptype == .test {///可能一个手机安装两个APP
                address = address - 50
            }
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
        } failure: { error in
            
            ///如果是token失效，不需要提示
            if error.code == 401 {
                return
            }
            
            if apptype == .test { //测试版APP不提示
                return
            }
            
            var message: String = error.userInfo["egMsg"] as! String
            if Bundle.isChineseLanguage() {
                message = error.userInfo["error"] as! String
            }
            
            KLMAlertController.showAlertWithTitle(title: LANGLOC("Failed to get the address from the server. Please make sure the network is normal and then refresh the page"), message: message)
            
        }
    }
    
    ///保存配置数据同时提交到服务器
    static func save() -> Bool {
       
        if MeshNetworkManager.instance.save() {
            
            if var model = KLMMesh.loadHome() {
                let manager = MeshNetworkManager.instance
                let data = manager.export(.full)
                let newStr = String(data: data, encoding: .utf8)
                ///本地的数据要变更
                model.meshConfiguration = newStr!
                KLMMesh.saveHome(home: model)
                
                ///提交到服务器
                KLMService.editMesh(id: model.id, meshName: nil, meshConfiguration: newStr) { response in
                    KLMLog("配置数据提交成功")
                    
                } failure: { error in
                    SVProgressHUD.dismiss()
                    
                    ///如果是token失效，不需要提示
                    if error.code == 401 {
                        return
                    }
                    
                    if apptype == .test { //测试版APP不提示
                        return
                    }
                    ///弹出提示框
                    KLMAlertController.showAlertWithTitle(title: nil, message: LANGLOC("DataUploadFail"))
                    
                }
            }
            return true
        }
        return false
    }
    
}

extension KLMMesh {
    
    ///将配置数据字符串转化成模型数据
    static func getMeshNetwork(meshConfiguration: String) -> MeshNetwork {
        
        let data = meshConfiguration.data(using: String.Encoding.utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let meshNetwork = try! decoder.decode(MeshNetwork.self, from: data)
        return meshNetwork
    }
}

extension KLMMesh {
    //退出登录
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
