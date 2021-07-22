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
    
    //原来设备所属分组
    var originalGroup: Group!
    
    //当前设备
    var currentDevice: Node!
    
    private var groups: [Group]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("transferTo")
        
        KLMMessageManager.sharedInstacnce.delegate = self
        
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
        
        //设备添加到群组
        guard let selectedIndexPath = selectedIndexPath else { return  }
        
        SVProgressHUD.show()
        let group = groups[selectedIndexPath.row]
        
        KLMMessageManager.sharedInstacnce.addNodeToGroup(withNode: KLMHomeManager.currentNode, withGroup: group)
        
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
            
            //设备从当前群组中移除
            KLMMessageManager.sharedInstacnce.deleteNodeToGroup(withNode: currentDevice, withGroup: self.originalGroup)
            
        }
        
        //设备移除成功
        if self.deviceStatus == .deviceDeleteFromGroup {
            
            SVProgressHUD.showSuccess(withStatus: "success")
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
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model: Group = groups[indexPath.row]
        let cell = KLMGroupSelectCell.cellWithTableView(tableView: tableView)
        if selectedIndexPath == indexPath {
            cell.setIsSelect = true
            
        } else {
            
            cell.setIsSelect = false
            
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



