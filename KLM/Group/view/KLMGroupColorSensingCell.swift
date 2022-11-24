//
//  KLMGroupColorSensingCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/26.
//

import UIKit
import nRFMeshProvision

class KLMGroupColorSensingCell: KLMBaseTableViewCell {
    
    @IBOutlet weak var onBtn: UIButton!
    @IBOutlet weak var offBtn: UIButton!
    
    var model: GroupData! {
        didSet {
            if model.colorSensing == 2 { //关
                offBtn.isSelected = true
                onBtn.isSelected = false
            } else { //开 1
                onBtn.isSelected = true
                offBtn.isSelected = false
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        onBtn.layer.cornerRadius = 4.0
        offBtn.layer.cornerRadius = 4.0
        onBtn.clipsToBounds = true
        offBtn.clipsToBounds = true
        
        onBtn.layer.borderWidth = 1
        offBtn.layer.borderWidth = 1
        
        onBtn.layer.borderColor = UIColor.lightGray.cgColor
        offBtn.layer.borderColor = UIColor.lightGray.cgColor
        
        onBtn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
        onBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        
        offBtn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
        offBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        
        onBtn.setTitleColor(appMainThemeColor, for: .normal)
        offBtn.setTitleColor(appMainThemeColor, for: .normal)
    }
    
    @IBAction func onClick(_ sender: Any) {
        
        let parame = parameModel(dp: .cameraPower, value: 1)
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            SVProgressHUD.show()
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) { [weak self] source in
                SVProgressHUD.dismiss()
                
                KLMLog("success")
                guard let self = self else { return }
                
                if let network = MeshNetworkManager.instance.meshNetwork {
                    
                    let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
                    if notConfiguredNodes.contains(where: {$0.isCamera}) == false {
                        SVProgressHUD.showInfo(withStatus: LANGLOC("The device do not support"))
                        return
                    }
                }
                
                self.onBtn.isSelected = true
                self.offBtn.isSelected = false
                self.sendData()
            } failure: { error in
                KLMShowError(error)
            }

        } else {
            
            SVProgressHUD.show()
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) { [weak self] source in
                SVProgressHUD.dismiss()
                
                KLMLog("success")
                guard let self = self else { return }
                
                ///如果组里面都是无摄像头的设备，不给点击
                let network = MeshNetworkManager.instance.meshNetwork!
                let models = network.models(subscribedTo: KLMHomeManager.currentGroup)
                var nodeLists = [Node]()
                for model in models {
                    
                    let node = KLMHomeManager.getNodeFromModel(model: model)!
                    nodeLists.append(node)
                }
                if nodeLists.contains(where: {$0.isCamera}) == false {
                    SVProgressHUD.showInfo(withStatus: LANGLOC("The device do not support"))
                    return
                }
                
                self.onBtn.isSelected = true
                self.offBtn.isSelected = false
                self.sendData()
            } failure: { error in
                KLMShowError(error)
            }
        }
        
    }
    
    @IBAction func offClick(_ sender: Any) {
        
        
        let parame = parameModel(dp: .cameraPower, value: 2)
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            SVProgressHUD.show()
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) { [weak self] source in
                SVProgressHUD.dismiss()
                KLMLog("success")
                guard let self = self else { return }
                
                if let network = MeshNetworkManager.instance.meshNetwork {
                    
                    let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
                    if notConfiguredNodes.contains(where: {$0.isCamera}) == false {
                        SVProgressHUD.showInfo(withStatus: LANGLOC("The device do not support"))
                        return
                    }
                }
                
                self.onBtn.isSelected = false
                self.offBtn.isSelected = true
                self.sendData()

                
            } failure: { error in
                KLMShowError(error)
            }
            
        } else {
            
            SVProgressHUD.show()
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) { [weak self] source in
                SVProgressHUD.dismiss()
                KLMLog("success")
                guard let self = self else { return }
                
                ///如果组里面都是无摄像头的设备，不给点击
                let network = MeshNetworkManager.instance.meshNetwork!
                let models = network.models(subscribedTo: KLMHomeManager.currentGroup)
                var nodeLists = [Node]()
                for model in models {
                    
                    let node = KLMHomeManager.getNodeFromModel(model: model)!
                    nodeLists.append(node)
                }
                if nodeLists.contains(where: {$0.isCamera}) == false {
                    SVProgressHUD.showInfo(withStatus: LANGLOC("The device do not support"))
                    return
                }
                
                self.onBtn.isSelected = false
                self.offBtn.isSelected = true
                self.sendData()
                
            } failure: { error in
                KLMShowError(error)
            }
        }
    }
    
    ///将参数提交到服务器
    private func sendData() {
        
        var address: Int = 0
        if KLMHomeManager.sharedInstacnce.controllType == .Group {
            address = Int(KLMHomeManager.currentGroup.address.address)
        }
        
        model.colorSensing = onBtn.isSelected ? 1 : 2
        KLMService.updateGroup(groupId: address, groupData: model) { response in
            
        } failure: { error in
            
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
