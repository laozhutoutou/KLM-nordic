//
//  KLMGroupViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit
import nRFMeshProvision

class KLMGroupViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var groups: [Group] = [Group]()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(moreClick))
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .groupRenameSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .groupAddSuccess, object: nil)    
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceRemoveFromGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddToGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceTransferSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceReset, object: nil)
        
        setupData()
    }
    
    @objc func setupData() {
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            self.groups = network.groups
            self.tableView.reloadData()
        }
    }
    
    /// 更多
    @objc func moreClick() {
        
        let vc = CMDeviceNamePopViewController()
        vc.nametype = .nameTypeNewGroup
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.nameBlock = {[weak self] name in
            SVProgressHUD.show()
            
            guard let self = self else { return }
            
            if let network = MeshNetworkManager.instance.meshNetwork,
               let localProvisioner = network.localProvisioner {
                
                if let automaticAddress = network.nextAvailableGroupAddress(for: localProvisioner) {
                    
                    let address = MeshAddress(automaticAddress)
                    let group = try? Group(name: name, address: address)
                    try? network.add(group: group!)
                    
                    if MeshNetworkManager.instance.save() {
                        
                        SVProgressHUD.showSuccess(withStatus: "success")
                        self.setupData()
                    }
                }
                
            }
            
        }
        self.tabBarController?.present(vc, animated: true, completion: nil)
        
    }

}

extension KLMGroupViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return groups.count

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 64
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model: Group = groups[indexPath.row]
        let cell = KLMGroupSelectCell.cellWithTableView(tableView: tableView)
        cell.model = model
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model: Group = groups[indexPath.row]
        
        KLMHomeManager.sharedInstacnce.smartGroup = model
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let models = network.models(subscribedTo: model)
        if models.isEmpty {

            SVProgressHUD.showInfo(withStatus: "No Devices")
            return
        }
        
        //是否有相机权限
        KLMPhotoManager().photoAuthStatus { [weak self] in
            guard let self = self else { return }

            let vc = KLMImagePickerController()
            vc.sourceType = UIImagePickerController.SourceType.camera
            self.tabBarController?.present(vc, animated: true, completion: nil)

        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let model: Group = groups[indexPath.row]
        
        let deleteAction = UIContextualAction.init(style: .destructive, title: LANGLOC("delete")) { action, sourceView, completionHandler in
            
            let aler = UIAlertController.init(title: LANGLOC("groupDeleteTip"), message: LANGLOC("groupSelectDelete"), preferredStyle: .alert)
            let cancel = UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil)
            let sure = UIAlertAction.init(title: LANGLOC("sure"), style: .default) { action in
                
                let network = MeshNetworkManager.instance.meshNetwork!
                do {
                    try network.remove(group: model)
                    
                    if MeshNetworkManager.instance.save() {
                        SVProgressHUD.showSuccess(withStatus: "success")
                        self.setupData()
                        
                    }
                } catch {
                    KLMShowError(error)
                    
                }
                
            }
            aler.addAction(cancel)
            aler.addAction(sure)
            self.tabBarController?.present(aler, animated: true, completion: nil)
            
            completionHandler(true)
        }
        
        //整组设置
        let editAction = UIContextualAction.init(style: .normal, title: LANGLOC("groupSetting")) { action, sourceView, completionHandler in
            
            let vc = KLMGroupEditViewController()
            vc.group = model
            self.navigationController?.pushViewController(vc, animated: true)
            
            completionHandler(true)
        }
        editAction.backgroundColor = appMainThemeColor
        let actions = UISwipeActionsConfiguration.init(actions: [deleteAction, editAction])
        return actions
    }
}

