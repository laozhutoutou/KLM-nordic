//
//  KLMGroupTransferListViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit
import nRFMeshProvision

enum deviceStatus {
    case deviceAddtoGroup
    case deviceDeleteFromGroup
}

class KLMGroupTransferListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var deviceStatus: deviceStatus = .deviceAddtoGroup
    
    //选择的
    private var selectedIndexPath: IndexPath?
    
    //当前设备
    var currentDevice: Node!
    
    private var groups: [Group]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMMessageManager.sharedInstacnce.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("transfer")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(newGroup))
        
        setupData()
    }
    
    func setupData() {
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let model = KLMHomeManager.getModelFromNode(node: currentDevice)!
        let alreadySubscribedGroups = model.subscriptions
        groups = network.groups.filter {
            !alreadySubscribedGroups.contains($0)
        }
        self.tableView.reloadData()

    }

    @IBAction func finishClick(_ sender: Any) {
        
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        //设备添加到群组
        guard let selectedIndexPath = selectedIndexPath else { return  }
        
        SVProgressHUD.show()
        let group = groups[selectedIndexPath.row]
        
        KLMMessageManager.sharedInstacnce.addNodeToGroup(withNode: currentDevice, withGroup: group)
        
    }
    
    @objc func newGroup() {
        
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        let vc = CMDeviceNamePopViewController()
        vc.titleName = LANGLOC("Group")
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.nameBlock = {[weak self] name in
            
            SVProgressHUD.show()
            
            guard let self = self else { return }
            
            if let network = MeshNetworkManager.instance.meshNetwork,
               let localProvisioner = network.localProvisioner {
                // Try assigning next available Group Address.
                if let automaticAddress = network.nextAvailableGroupAddress(for: localProvisioner) {
                    
                    //提交分组到服务器
                    KLMService.addGroup(groupId: Int(automaticAddress), groupName: name) { response in
                        KLMLog("分组提交成功到服务器")
                        
                        let address = MeshAddress(automaticAddress)
                        let group = try? Group(name: name, address: address)
                        try? network.add(group: group!)
                        
                        if KLMMesh.save() {
                            
                            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                            NotificationCenter.default.post(name: .groupAddSuccess, object: nil)
                            self.setupData()
                        }
                        
                    } failure: { error in
                        KLMHttpShowError(error)
                    }
                }
                
            }

        }
        present(vc, animated: true, completion: nil)
        
    }
}

extension KLMGroupTransferListViewController: KLMMessageManagerDelegate {
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {
        
        if error != nil {
            
            SVProgressHUD.showError(withStatus: error?.message)
            return
        }
        
        //设备添加进群组成功
        if self.deviceStatus == .deviceAddtoGroup {
            self.deviceStatus = .deviceDeleteFromGroup
            ///提交数据到服务器
            if KLMMesh.save() {
                
            }
            //设备从当前群组中移除
            KLMMessageManager.sharedInstacnce.deleteNodeToGroup(withNode: currentDevice, withGroup: KLMHomeManager.currentGroup)
            
        }
        
        //设备移除成功
        if self.deviceStatus == .deviceDeleteFromGroup {
            
            ///提交数据到服务器
            if KLMMesh.save() {
                
            }
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            DispatchQueue.main.asyncAfter(deadline: 1) {
                NotificationCenter.default.post(name: .deviceTransferSuccess, object: nil)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}

extension KLMGroupTransferListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return groups.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 64
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model: Group = groups[indexPath.row]
        let cell = KLMGroupSelectCell.cellWithTableView(tableView: tableView)
        if selectedIndexPath == indexPath {
            cell.isShowSelect = true
            
        } else {
            
            cell.isShowSelect = false
            
        }
        
        cell.model = model
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedIndexPath = indexPath
        tableView.reloadData()
    }
}



