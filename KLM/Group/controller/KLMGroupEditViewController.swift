//
//  KLMGroupEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit
import nRFMeshProvision

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
        
        return 2
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let cell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        switch indexPath.row {
        case 0:
            cell.leftTitle = LANGLOC("reNameGroup")
            cell.rightTitle = self.group.name
        case 1:
            cell.leftTitle = LANGLOC("groupMembers")
            let network = MeshNetworkManager.instance.meshNetwork!
            let models = network.models(subscribedTo: group)
            cell.rightTitle = String(format: "%d%@", models.count,LANGLOC("geDevice"))
            
        default: break
            
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            //修改组名称
            let vc = CMDeviceNamePopViewController()
            vc.titleName = LANGLOC("Group")
            vc.text = self.group.name
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.nameBlock = {[weak self] name in
                guard let self = self else { return  }
                
                self.group.name = name
                
                if MeshNetworkManager.instance.save() {
                    
                    self.tableView.reloadData()
                    NotificationCenter.default.post(name: .groupRenameSuccess, object: nil)
                }
                
            }
            self.present(vc, animated: true, completion: nil)
        case 1:
            let vc = KLMGroupDeviceEditViewController()
            vc.groupModel = self.group
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
