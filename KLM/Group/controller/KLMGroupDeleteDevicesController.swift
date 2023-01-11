//
//  KLMGroupDeleteDevicesController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/23.
//

import UIKit
import nRFMeshProvision

class KLMGroupDeleteDevicesController: UITableViewController {
    
    //设备数据源
    var nodes: [Node] = [Node]()
    var selectNodes: [Node] = [Node]()
    var currentIndex: Int = 0
    /// 是否来自转移
    var isFromTransfer: Bool = false
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMMessageManager.sharedInstacnce.delegate = self
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("Delete devices")
        if isFromTransfer {
            navigationItem.title = LANGLOC("Devices transfer")
        }
        
        tableView.separatorStyle = .none
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("Done"), target: self, action: #selector(finishClick))
    }
    
    @objc private func setupData(){
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let models = network.models(subscribedTo: KLMHomeManager.currentGroup)
        nodes.removeAll()
        for model in models {
            
            let node = KLMHomeManager.getNodeFromModel(model: model)
            nodes.append(node!)
        }
        self.tableView.reloadData()
    }
    
    @objc func finishClick() {
        
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        //设备删除
        if selectNodes.isEmpty {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please select devices"))
            return
        }
        
        if isFromTransfer {
            let vc = KLMGroupTransferListViewController()
            vc.selectNodes = selectNodes
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        let aler = UIAlertController.init(title: LANGLOC("Delete devices"), message: nil, preferredStyle: .alert)
        let cancel = UIAlertAction.init(title: LANGLOC("Cancel"), style: .cancel, handler: nil)
        let sure = UIAlertAction.init(title: LANGLOC("Confirm"), style: .default) { action in
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            self.next()
            
        }
        aler.addAction(cancel)
        aler.addAction(sure)
        self.present(aler, animated: true, completion: nil)
    }
    
    private func next() {
        
        if currentIndex >= selectNodes.count { ///全部删除完成
            
            ///提交数据到服务器
            if KLMMesh.save() {
                
            }

            NotificationCenter.default.post(name: .deviceRemoveFromGroup, object: nil)
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            self.navigationController?.popViewController(animated: true)
            
            return
        }
        
        let selectNode = selectNodes[currentIndex]
        KLMMessageManager.sharedInstacnce.deleteNodeToGroup(withNode: selectNode, withGroup: KLMHomeManager.currentGroup)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.nodes.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 80
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let node = self.nodes[indexPath.row]
        let cell = KLMGroupDeviceAddCell.cellWithTableView(tableView: tableView)
        cell.model = node
        if selectNodes.contains(where: {$0.uuid == node.uuid}) {
            cell.isShowSelect = true
        } else {
            cell.isShowSelect = false
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let node = self.nodes[indexPath.row]
        if let index = selectNodes.firstIndex(where: {$0.uuid == node.uuid}) {
            selectNodes.remove(at: index)
            tableView.reloadData()
        } else {
            
            if selectNodes.count >= 10 {
                
                SVProgressHUD.showInfo(withStatus: String.init(format: LANGLOC("Select at most %d lights"), selectNodes.count))
                return
            }
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToNode(node: node) {
                SVProgressHUD.dismiss()
                self.selectNodes.append(node)
                tableView.reloadData()
            } failure: {
                
            }
        }
    }
}

extension KLMGroupDeleteDevicesController: KLMMessageManagerDelegate {
    
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {
        
        let selectNode = selectNodes[currentIndex]
        KLMService.removeDeviceFromGroup(groupId: Int(KLMHomeManager.currentGroup.address.address), uuid: selectNode.nodeuuidString) { response in
            
        } failure: { error in
            
        }
        
        currentIndex += 1
        next()
    
    }
}
