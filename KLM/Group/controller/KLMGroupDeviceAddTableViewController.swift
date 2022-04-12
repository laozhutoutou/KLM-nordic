//
//  KLMGroupDeviceAddTableViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/8.
//

import UIKit
import nRFMeshProvision

class KLMGroupDeviceAddTableViewController: UITableViewController {
    
    //设备数据源
    var nodes: [Node] = [Node]()
    private var selectedIndexPath: IndexPath?
    //当前分组
    var groupModel: Group!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMMessageManager.sharedInstacnce.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("unGroup")
        
        tableView.separatorStyle = .none
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finishClick))

        setupData()
    }
    
    func setupData(){
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            
            //过滤组中设备
            for node in notConfiguredNodes {
                let model = KLMHomeManager.getModelFromNode(node: node)
//                if let boo = model?.isSubscribed(to: groupModel), boo == false {
//
//                    self.nodes.append(node)
//                }
                if model?.subscriptions.count == 0 { ///设备没添加进分组
                    self.nodes.append(node)
                }
            }
            self.tableView.reloadData()
            
        }
    }
    
    @objc func finishClick() {
        
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        //设备添加到群组
        guard let selectedIndexPath = selectedIndexPath else { return  }
        
        //查询设备是否在线
        let selectNode = self.nodes[selectedIndexPath.row]
        if !selectNode.isCompositionDataReceived {
            //对于未composition的进行配置
            SVProgressHUD.show(withStatus: "Composition")
            SVProgressHUD.setDefaultMaskType(.black)
            
            KLMSIGMeshManager.sharedInstacnce.delegate = self
            KLMSIGMeshManager.sharedInstacnce.getCompositionData(node: selectNode)
            return
        }
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        KLMConnectManager.shared.connectToNode(node: selectNode) { [weak self] in
            guard let self = self else { return }
            
            KLMMessageManager.sharedInstacnce.addNodeToGroup(withNode: selectNode, withGroup: self.groupModel)
            
        } failure: {
            
        }
        
        
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
        if selectedIndexPath == indexPath {
            cell.isShowSelect = true
            
        } else {
            
            cell.isShowSelect = false
            
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedIndexPath = indexPath
        tableView.reloadData()
        
    }
}

extension KLMGroupDeviceAddTableViewController: KLMMessageManagerDelegate {
    
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {
        
        if error != nil {
            
            SVProgressHUD.showError(withStatus: error?.message)
            return
        }
        
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        
        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
        NotificationCenter.default.post(name: .deviceAddToGroup, object: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension KLMGroupDeviceAddTableViewController: KLMSIGMeshManagerDelegate {
        
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node) {
        
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        
        SVProgressHUD.showSuccess(withStatus: "Please tap \(LANGLOC("finish")) again")
        
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?){
        
        KLMShowError(error)
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didSendMessage message: MeshMessage) {
        
        SVProgressHUD.show(withStatus: "Did send message")
    }
}
