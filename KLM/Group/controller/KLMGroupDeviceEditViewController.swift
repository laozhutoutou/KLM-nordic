//
//  KLMGroupDeviceEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit
import nRFMeshProvision

class KLMGroupDeviceEditViewController: UIViewController {
    
   
    @IBOutlet weak var tableView: UITableView!
    
    //当前分组
    var groupModel: Group!
    
    //数据源
    lazy var deviceLists: [Node] = {
        let  deviceLists = [Node]()
        return deviceLists
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMMessageManager.sharedInstacnce.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = self.groupModel.name
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceTransferSuccess, object: nil)
        
        setupData()
        
    }
    
    @objc func setupData(){
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let models = network.models(subscribedTo: groupModel)
        self.deviceLists.removeAll()
        for model in models {
            
            let node = KLMHomeManager.getNodeFromModel(model: model)
            self.deviceLists.append(node!)
        }
        self.tableView.reloadData()
    }
    
}

extension KLMGroupDeviceEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.deviceLists.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let deviceModel:  Node = self.deviceLists[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.leftImage = "img_scene_48"
        cell.leftTitle = deviceModel.nodeName
        return cell
    
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let node = self.deviceLists[indexPath.row]
        
        //记录当前设备
        KLMHomeManager.sharedInstacnce.smartNode = node
        
        //是否有相机权限
        KLMPhotoManager().photoAuthStatus { [weak self] in
            guard let self = self else { return }
            
            let vc = KLMImagePickerController()
            vc.sourceType = UIImagePickerController.SourceType.camera
            self.tabBarController?.present(vc, animated: true, completion: nil)
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deviceModel: Node = self.deviceLists[indexPath.item]
        
        let deleteAction = UIContextualAction.init(style: .destructive, title: LANGLOC("delete")) { action, sourceView, completionHandler in
            
            let aler = UIAlertController.init(title: LANGLOC("deviceMoveOutGroupTip"), message: LANGLOC("deviceMoveOutGroup"), preferredStyle: .alert)
            let cancel = UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil)
            let sure = UIAlertAction.init(title: LANGLOC("sure"), style: .default) { action in
                
                //设备移出分组
                SVProgressHUD.show()
                
                //设备从当前群组中移除
                KLMMessageManager.sharedInstacnce.deleteNodeToGroup(withNode: deviceModel, withGroup: self.groupModel)
                
            }
            aler.addAction(cancel)
            aler.addAction(sure)
            self.tabBarController?.present(aler, animated: true, completion: nil)
            
            completionHandler(true)
        }
        
        //转移
        let editAction = UIContextualAction.init(style: .normal, title: LANGLOC("transfer")) { action, sourceView, completionHandler in
            
            let vc = KLMGroupTransferListViewController()
            vc.currentDevice =  deviceModel
            vc.originalGroup = self.groupModel
            self.navigationController?.pushViewController(vc, animated: true)
            
            completionHandler(true)
        }
        
        editAction.backgroundColor = appMainThemeColor
        let actions = UISwipeActionsConfiguration.init(actions: [deleteAction, editAction])
        return actions
    }
}

extension KLMGroupDeviceEditViewController: KLMMessageManagerDelegate {
    
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {
        
        if error != nil {
            
            SVProgressHUD.showError(withStatus: error?.message)
            return
        }
        
        SVProgressHUD.showSuccess(withStatus: "success")
        NotificationCenter.default.post(name: .deviceRemoveFromGroup, object: nil)
        
        self.setupData()
    }
    
}

