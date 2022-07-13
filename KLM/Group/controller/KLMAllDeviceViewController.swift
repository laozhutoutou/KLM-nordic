//
//  KLMAllDeviceViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/3/7.
//

import UIKit

private enum itemType: Int, CaseIterable {
    case lightPower = 0
    case lightSetting
    case motion
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

        navigationItem.title = LANGLOC("allDevice")
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
            cell.leftTitle = LANGLOC("lightSet")
            cell.rightTitle = ""
            return cell
        case itemType.motion.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Energysavingsettings")
            cell.rightTitle = self.groupData.energyPower == 1 ? LANGLOC("ON") : LANGLOC("OFF")
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
                guard let self = self else { return }
                //是否有相机权限
                KLMPhotoManager().photoAuthStatus { [weak self] in
                    guard let self = self else { return }

                    let vc = KLMImagePickerController()
                    vc.sourceType = .camera
                    self.present(vc, animated: true, completion: nil)

                }
            } failure: {
                
            }
            
        case itemType.motion.rawValue:
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToAllNodes { [weak self] in
                guard let self = self else { return }
                let vc = KLMGroupMotionViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            } failure: {
                
            }
            
        default:
            break
        }
    }
}
