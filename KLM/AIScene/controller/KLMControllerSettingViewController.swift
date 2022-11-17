//
//  KLMControllerSettingViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/15.
//

import UIKit
import nRFMeshProvision

private enum itemType: Int, CaseIterable {
  
    case lightPower = 0
    case lightSetting
//    case DFU
    case rename
//    case group
    case reset
}

class KLMControllerSettingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nameLab: UILabel!
    
    private var lightSwitch = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        event()
    }
    
    func setupUI() {
        
        self.navigationItem.title = LANGLOC("setting")
        nameLab.text = KLMHomeManager.currentNode.nodeName
        
        view.backgroundColor = appBackGroupColor
        tableView.backgroundColor = appBackGroupColor
        
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
    }
    
    func event() {
        
        
    }

}

extension KLMControllerSettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return itemType.allCases.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        return 56
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
            
        case itemType.lightPower.rawValue:///灯开关
            let cell: KLMLightOnOffCell = KLMLightOnOffCell.cellWithTableView(tableView: tableView)
            cell.onOff = self.lightSwitch
            return cell
        case itemType.lightSetting.rawValue:
            
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("lightSet")
            cell.rightTitle = ""
            return cell
        case itemType.rename.rawValue:
            
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("reName")
            cell.rightTitle = KLMHomeManager.currentNode.nodeName
            return cell
        
        case itemType.reset.rawValue://恢复出厂设置
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("restorefactorysettings")
            cell.rightTitle = ""
            return cell

        default:
            break
        }
        
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case itemType.rename.rawValue://设备名称
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            let vc = CMDeviceNamePopViewController()
            vc.titleName = LANGLOC("Light")
            vc.text = KLMHomeManager.currentNode.name
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.nameBlock = {[weak self] name in
                guard let self = self else { return }
                
                if let network = MeshNetworkManager.instance.meshNetwork {
                    
                    let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
                    if notConfiguredNodes.contains(where: {$0.name == name}) {
                        SVProgressHUD.showInfo(withStatus: LANGLOC("The name already exists"))
                        return
                    }
                }
                
                KLMHomeManager.currentNode.name = name
                
                if KLMMesh.save() {
                    
                    self.nameLab.text = KLMHomeManager.currentNode.name
                    self.tableView.reloadData()
                }
                
                //发送通知更新首页
                NotificationCenter.default.post(name: .deviceNameUpdate, object: nil)
                
            }
            present(vc, animated: true, completion: nil)
                        
        case itemType.lightSetting.rawValue://灯光设置
            
            let vc = KLMControllerOperationViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        case itemType.reset.rawValue: //恢复出厂设置
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            let vc = UIAlertController.init(title: LANGLOC("restorefactorysettings"), message: nil, preferredStyle: .alert)
            vc.addAction(UIAlertAction.init(title: LANGLOC("Reset"), style: .default, handler: { action in
                SVProgressHUD.show()
                KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)

            }))
            vc.addAction(UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil))
            present(vc, animated: true, completion: nil)
        default:
            
            break
        }
    }
}
