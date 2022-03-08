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
    case rename
    case groupMembers
    
}

class KLMGroupEditViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    //当前分组
    var group: Group!
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("groupSetting")
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceRemoveFromGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddToGroup, object: nil)
    }
    
    @objc func setupData() {
        
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
            cell.rightTitle = self.group.name
            return cell
        case itemType.groupMembers.rawValue:
            let cell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("groupMembers")
            let network = MeshNetworkManager.instance.meshNetwork!
            let models = network.models(subscribedTo: group)
            cell.rightTitle = String(format: "%d%@", models.count,LANGLOC("geDevice"))
            return cell
        case itemType.lightPower.rawValue: ///开关
            let cell: KLMGroupPowerCell = KLMGroupPowerCell.cellWithTableView(tableView: tableView)
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
            vc.text = self.group.name
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.nameBlock = {[weak self] name in
                guard let self = self else { return  }
                
                self.group.name = name
                
                if KLMMesh.save() {
                    
                    self.tableView.reloadData()
                    NotificationCenter.default.post(name: .groupRenameSuccess, object: nil)
                }
                
            }
            self.present(vc, animated: true, completion: nil)
        case itemType.groupMembers.rawValue:
            let vc = KLMGroupDeviceEditViewController()
            vc.groupModel = self.group
            navigationController?.pushViewController(vc, animated: true)
        case itemType.lightSetting.rawValue://灯光设置
            //是否有相机权限
            KLMPhotoManager().photoAuthStatus { [weak self] in
                guard let self = self else { return }
                
                let vc = KLMImagePickerController()
                vc.sourceType = UIImagePickerController.SourceType.camera
                self.present(vc, animated: true, completion: nil)
                
            }
        case itemType.motion.rawValue:
            let vc = KLMGroupMotionViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
