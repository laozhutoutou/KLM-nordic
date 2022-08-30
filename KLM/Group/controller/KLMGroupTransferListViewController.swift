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
    
    var deviceStatus: deviceStatus = .deviceDeleteFromGroup
    
    //选择的
    private var selectedIndexPath: IndexPath?
    var selectNodes: [Node]!
    var currentIndex: Int = 0
    private var groups: [Group]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMMessageManager.sharedInstacnce.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("Select a group")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(newGroup))
        
        setupData()
    }
    
    func setupData() {
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let model = KLMHomeManager.getModelFromNode(node: selectNodes.first!)!
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
        
        if selectedIndexPath == nil {
            return
        }
        
        SVProgressHUD.show()
        removeDevice()
        
    }
    
    ///设备从旧分组移除
    private func removeDevice() {
        
        let selectNode = selectNodes[currentIndex]
        KLMMessageManager.sharedInstacnce.deleteNodeToGroup(withNode: selectNode, withGroup: KLMHomeManager.currentGroup)
    }
    ///设备添加进新分组
    private func addDevice() {
        
        let selectNode = selectNodes[currentIndex]
        let group = groups[selectedIndexPath!.row]
        KLMMessageManager.sharedInstacnce.addNodeToGroup(withNode: selectNode, withGroup: group)
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
}

extension KLMGroupTransferListViewController: KLMMessageManagerDelegate {
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {
        
        if KLMMesh.save() {
            
        }
        
        if error != nil {
            
            SVProgressHUD.showInfo(withStatus: error?.message)
            return
        }
        
        //设备添加进群组成功
        if self.deviceStatus == .deviceAddtoGroup {
            self.deviceStatus = .deviceDeleteFromGroup
            currentIndex += 1
            if currentIndex >= selectNodes.count {
                
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                NotificationCenter.default.post(name: .deviceTransferSuccess, object: nil)
                ///KLMGroupDeviceEditViewController
                var targetVC : UIViewController!
                for controller in self.navigationController!.viewControllers {
                    if controller.isKind(of: KLMGroupDeviceEditViewController.self) {
                        targetVC = controller
                    }
                }
                if targetVC != nil {
                    self.navigationController?.popToViewController(targetVC, animated: true)
                }
            } else {
                
                removeDevice()
            }
        } else { //设备移除成功
            
            self.deviceStatus = .deviceAddtoGroup
            addDevice()
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



