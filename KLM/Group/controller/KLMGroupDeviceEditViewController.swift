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
        
        self.navigationItem.title = KLMHomeManager.currentGroup.name
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceTransferSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddToGroup, object: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(addDevice))
        
        setupData()
        
    }
    
    @objc func setupData(){
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let models = network.models(subscribedTo: KLMHomeManager.currentGroup)
        self.deviceLists.removeAll()
        for model in models {
            
            let node = KLMHomeManager.getNodeFromModel(model: model)
            self.deviceLists.append(node!)
        }
        self.tableView.reloadData()
    }
    
    @objc func addDevice() {
        
        let vc = KLMGroupDeviceAddTableViewController()
        navigationController?.pushViewController(vc, animated: true)
        
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
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        KLMConnectManager.shared.connectToNode(node: node) { [weak self] in
            guard let self = self else { return }
            
            if apptype == .test {
                
                let vc = KLMTestSectionTableViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                
                return
            }
            
            let vc = KLMDeviceEditViewController()
            self.navigationController?.pushViewController(vc, animated: true)
            
        } failure: {
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deviceModel: Node = self.deviceLists[indexPath.item]
        
        let deleteAction = UIContextualAction.init(style: .destructive, title: LANGLOC("delete")) { action, sourceView, completionHandler in
            
            let aler = UIAlertController.init(title: LANGLOC("deviceMoveOutGroupTip"), message: LANGLOC("deviceMoveOutGroup"), preferredStyle: .alert)
            let cancel = UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil)
            let sure = UIAlertAction.init(title: LANGLOC("sure"), style: .default) { action in
                
                if KLMMesh.isCanEditMesh() == false {
                    return
                }
                
                //设备移出分组
                SVProgressHUD.show()
                
                //设备从当前群组中移除
                KLMMessageManager.sharedInstacnce.deleteNodeToGroup(withNode: deviceModel, withGroup: KLMHomeManager.currentGroup)
                
            }
            aler.addAction(cancel)
            aler.addAction(sure)
            self.present(aler, animated: true, completion: nil)
            
            completionHandler(true)
        }
        
        //转移
        let editAction = UIContextualAction.init(style: .normal, title: LANGLOC("transfer")) { action, sourceView, completionHandler in
            
            let vc = KLMGroupTransferListViewController()
            vc.currentDevice =  deviceModel
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
        ///提交到服务器
        if KLMMesh.save() {
            
        }
        
        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
        NotificationCenter.default.post(name: .deviceRemoveFromGroup, object: nil)
        
        self.setupData()
    }
    
}

extension KLMGroupDeviceEditViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {

        let contentView = UIView()
        
        let image = UIImageView.init(image: UIImage.init(named: "img_Empty_Status"))
        contentView.addSubview(image)
        image.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        let titleLab = UILabel()
        titleLab.text = LANGLOC("noDevice")
        titleLab.font = UIFont.systemFont(ofSize: 14)
        titleLab.textColor = rgba(0, 0, 0, 0.5)
        contentView.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(image.snp.bottom).offset(10)
        }
        
        return contentView
    }
}

