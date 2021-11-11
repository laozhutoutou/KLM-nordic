//
//  KLMGroupDeviceAddToViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/17.
//

import UIKit
import nRFMeshProvision

class KLMGroupDeviceAddToViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var groups: [Group]!
    private var selectedIndexPath: IndexPath?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMMessageManager.sharedInstacnce.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("groupSetting")
    
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(newGroup))
        
        setupData()
    }
    
    @objc func newGroup() {
        
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
                    }
                }
                
            }

        }
        present(vc, animated: true, completion: nil)
        
    }
    
    
    func setupData() {
        
        let network = MeshNetworkManager.instance.meshNetwork!
        
        let alreadySubscribedGroups = KLMHomeManager.currentModel.subscriptions
        groups = network.groups.filter {
            !alreadySubscribedGroups.contains($0)
        }
        self.tableView.reloadData()
    
    }
    
    @IBAction func finishClick(_ sender: Any) {
        
        //设备添加到群组
        guard let selectedIndexPath = selectedIndexPath else { return  }
        
        SVProgressHUD.show()
        let group = groups[selectedIndexPath.row]
        
        KLMMessageManager.sharedInstacnce.addNodeToGroup(withNode: KLMHomeManager.currentNode, withGroup: group)
    }
}

extension KLMGroupDeviceAddToViewController: KLMMessageManagerDelegate {
    
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {
        
        if error != nil {
            
            SVProgressHUD.showError(withStatus: error?.message)
            return
        }
        
        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
        NotificationCenter.default.post(name: .deviceAddToGroup, object: nil)
        self.navigationController?.popViewController(animated: true)
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

