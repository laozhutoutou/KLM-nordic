//
//  KLMAllDeviceViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/3/7.
//

import UIKit
import nRFMeshProvision

private enum itemType: Int, CaseIterable {
    case lightPower = 0
    case lightSetting
    case motion
    case CMOS
}

class KLMAllDeviceViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var groupData: GroupData = GroupData()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("All devices")
    }
    
    private func setupData() {
        
        SVProgressHUD.show()
        KLMService.selectGroup(groupId: 0) { response in
            SVProgressHUD.dismiss()
            guard let model = response as? GroupData else { return  }
            self.groupData = model
            self.tableView.reloadData()
        } failure: { error in
            SVProgressHUD.dismiss()
            if error.code == 575 { //查询不到数据
                //提交本地的
                let mesh = KLMMesh.loadHome()!
                KLMService.addGroup(meshId: mesh.id, groupId: 0, groupName: "所有设备") { response in
                    
                } failure: { error in
                    
                }
            } else {
                KLMHttpShowError(error)
            }
        }
    }
}

extension KLMAllDeviceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return itemType.allCases.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        switch indexPath.row {
        case itemType.lightPower.rawValue: ///开关
            let cell: KLMGroupPowerCell = KLMGroupPowerCell.cellWithTableView(tableView: tableView)
            cell.model = self.groupData
            return cell
        case itemType.lightSetting.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Light setting")
            cell.rightTitle = ""
            return cell
        case itemType.motion.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Energy saving setting")
            cell.rightTitle = self.groupData.energyPower == 1 ? LANGLOC("On") : LANGLOC("Off")
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
        case itemType.lightSetting.rawValue://灯光设置
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToAllNodes { [weak self] in
                SVProgressHUD.dismiss()
                guard let self = self else { return }
                
                let vc = KLMLightSettingController()
                self.navigationController?.pushViewController(vc, animated: true)
                
            } failure: {

            }
            
        case itemType.motion.rawValue:
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToAllNodes { [weak self] in
                SVProgressHUD.dismiss()
                guard let self = self else { return }
                
                if let network = MeshNetworkManager.instance.meshNetwork {
                    
                    let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
                    if notConfiguredNodes.contains(where: {$0.deviceType == .camera}) == false {
                        SVProgressHUD.showInfo(withStatus: LANGLOC("The device do not support"))
                        return
                    }
                }
                
                let vc = KLMGroupMotionViewController()
                let nav = KLMNavigationViewController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true, completion: nil)
            } failure: {
                
            }
            
        default:
            break
        }
    }
}
