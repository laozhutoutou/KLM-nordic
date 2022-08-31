//
//  KLMGroupEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit
import nRFMeshProvision

private enum itemType: Int, CaseIterable {
    case lightPower = 0
    case lightSetting
    case motion
    case CMOS
    case rename
    case groupMembers
    
}

class KLMGroupEditViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var groupData: GroupData = GroupData()
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("groupSetting")
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .deviceRemoveFromGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .deviceAddToGroup, object: nil)
        
    }
    
    private func setupData() {
        
        SVProgressHUD.show()
        KLMService.selectGroup(groupId: Int(KLMHomeManager.currentGroup.address.address)) { response in
            SVProgressHUD.dismiss()
            guard let model = response as? GroupData else { return  }
            self.groupData = model
            self.tableView.reloadData()
        } failure: { error in
            SVProgressHUD.dismiss()
            if error.code == 575 { //查询不到数据
                //提交本地的
                let mesh = KLMMesh.loadHome()!
                KLMService.addGroup(meshId: mesh.id, groupId: Int(KLMHomeManager.currentGroup.address.address), groupName: KLMHomeManager.currentGroup.name) { response in
                    
                } failure: { error in
                    
                }
            } else {
                KLMHttpShowError(error)
            }
        }
    }
    
    @objc func reloadData() {
        
        self.tableView.reloadData()
    }
    
}

extension KLMGroupEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return itemType.allCases.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        switch indexPath.row {
        case itemType.rename.rawValue:
            let cell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("reNameGroup")
            cell.rightTitle = KLMHomeManager.currentGroup.name
            return cell
        case itemType.groupMembers.rawValue:
            let cell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("groupMembers")
            let network = MeshNetworkManager.instance.meshNetwork!
            let models = network.models(subscribedTo: KLMHomeManager.currentGroup)
            cell.rightTitle = String(format: "%d%@", models.count,LANGLOC("geDevice"))
            return cell
        case itemType.lightPower.rawValue: ///开关
            let cell: KLMGroupPowerCell = KLMGroupPowerCell.cellWithTableView(tableView: tableView)
            cell.model = self.groupData
            return cell
        case itemType.lightSetting.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("lightSet")
            cell.rightTitle = ""
            return cell
        case itemType.motion.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Energysavingsettings")
            cell.rightTitle = self.groupData.energyPower == 1 ? LANGLOC("ON") : LANGLOC("OFF")
            return cell
        case itemType.CMOS.rawValue://颜色识别
            let cell: KLMGroupColorSensingCell = KLMGroupColorSensingCell.cellWithTableView(tableView: tableView)
            cell.model = self.groupData
            return cell
        default: break
            
        }
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case itemType.rename.rawValue:
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            //修改组名称
            let vc = CMDeviceNamePopViewController()
            vc.titleName = LANGLOC("Group")
            vc.text = KLMHomeManager.currentGroup.name
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.nameBlock = {[weak self] name in
                guard let self = self else { return  }
                
                KLMHomeManager.currentGroup.name = name
                
                if KLMMesh.save() {
                    
                    self.tableView.reloadData()
                    NotificationCenter.default.post(name: .groupRenameSuccess, object: nil)
                }
                
            }
            self.present(vc, animated: true, completion: nil)
        case itemType.groupMembers.rawValue:
            let vc = KLMGroupDeviceEditViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.lightSetting.rawValue://灯光设置
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToGroup(group: KLMHomeManager.currentGroup) { [weak self] in

                guard let self = self else { return }
                
                let vc = KLMLightSettingController()
                self.navigationController?.pushViewController(vc, animated: true)
                
                //是否有相机权限
//                KLMPhotoManager().photoAuthStatus { [weak self] in
//                    guard let self = self else { return }
//
//                    let vc = KLMImagePickerController()
//                    vc.sourceType = .camera
//                    self.tabBarController?.present(vc, animated: true, completion: nil)
//
//                }
            } failure: {


            }
            
        case itemType.motion.rawValue:
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToGroup(group: KLMHomeManager.currentGroup) { [weak self] in
                
                guard let self = self else { return }
                
                let vc = KLMGroupMotionViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                
            } failure: {
                
            }
        case itemType.CMOS.rawValue:
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToGroup(group: KLMHomeManager.currentGroup) { [weak self] in
                
                guard let self = self else { return }
                
                let vc = KLMGroupUseOccasionViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                
            } failure: {
                
            }
        
        default:
            break
        }
    }
}
