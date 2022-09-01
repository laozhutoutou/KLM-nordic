//
//  KLMGroupDeviceAddToViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/17.
//

import UIKit
import nRFMeshProvision

class KLMGroupDeviceAddToViewController: UIViewController {
    
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private var groups: [Group]!
    private var selectedIndexPath: IndexPath?
    
    enum deviceStatus {
        case deviceAddtoGroup
        case deviceDeleteFromGroup
    }
    
    var deviceStatus: deviceStatus = .deviceDeleteFromGroup
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMMessageManager.sharedInstacnce.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("groupSetting")
        doneBtn.backgroundColor = appMainThemeColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(newGroup))
        
        setupData()
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
                    
                    let address = MeshAddress(automaticAddress)
                    let group = try? Group(name: name, address: address)
                    try? network.add(group: group!)
                    
                    if KLMMesh.save() {
                        
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                        NotificationCenter.default.post(name: .groupAddSuccess, object: nil)
                        self.setupData()
                        
                        let mesh = KLMMesh.loadHome()!
                        //提交分组到服务器
                        KLMService.addGroup(meshId: mesh.id, groupId: Int(automaticAddress), groupName: name) { response in
                            KLMLog("分组提交成功到服务器")
                            
                        } failure: { error in
                            KLMHttpShowError(error)
                        }
                    }
                }
            }
        }
        present(vc, animated: true, completion: nil)
        
    }
    
    
    func setupData() {
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let alreadySubscribedGroups = KLMHomeManager.currentModel.subscriptions
//        groups = network.groups.filter {
//            !alreadySubscribedGroups.contains($0)
//        }
        groups = network.groups
        if let index = groups.firstIndex(where: { item -> Bool in
            
            return alreadySubscribedGroups.contains(where: {$0.address == item.address})
                
        }) {
            
            selectedIndexPath = IndexPath.init(row: index, section: 0)

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
        
        if let oldGroup = KLMHomeManager.currentModel.subscriptions.first {
            self.deviceStatus = .deviceDeleteFromGroup
            ///将设备从旧分组删除
            KLMMessageManager.sharedInstacnce.deleteNodeToGroup(withNode: KLMHomeManager.currentNode, withGroup: oldGroup)
        } else {
            self.deviceStatus = .deviceAddtoGroup
            let group = groups[selectedIndexPath.row]
            KLMMessageManager.sharedInstacnce.addNodeToGroup(withNode: KLMHomeManager.currentNode, withGroup: group)
        }
    }
}

extension KLMGroupDeviceAddToViewController: KLMMessageManagerDelegate {
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {
        
        if error != nil {
            
            SVProgressHUD.showInfo(withStatus: error?.message)
            return
        }
        
        if self.deviceStatus == .deviceDeleteFromGroup {
            
            self.deviceStatus = .deviceAddtoGroup
            ///提交数据到服务器
            if KLMMesh.save() {
                
            }
            ///设备添加进新分组
            let group = groups[selectedIndexPath!.row]
            KLMMessageManager.sharedInstacnce.addNodeToGroup(withNode: KLMHomeManager.currentNode, withGroup: group)
        }
        
        if self.deviceStatus == .deviceAddtoGroup {
            
            ///提交数据到服务器
            if KLMMesh.save() {
                
            }
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            NotificationCenter.default.post(name: .deviceAddToGroup, object: nil)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
}

extension KLMGroupDeviceAddToViewController: UITableViewDelegate, UITableViewDataSource {
    
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

