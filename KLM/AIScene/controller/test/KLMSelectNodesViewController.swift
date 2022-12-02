//
//  KLMSelectNodesViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/1.
//

import UIKit
import nRFMeshProvision

class KLMSelectNodesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomBtn: UIButton!
    var nodes: [Node] = [Node]()
    var selectNodes: [Node] = [Node]()
    var isFromImage = false
    var currentIndex: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "点击选择设备"
        tableView.rowHeight = 70
        if isFromImage {
            bottomBtn.setTitle("查看图像", for: .normal)
        }
        setupData()
    }
    
    private func setupData(){
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            self.nodes.removeAll()
            self.nodes = notConfiguredNodes
            self.tableView.reloadData()
        }
        
    }
    
    private func resetNodes() {
        
        if let bearer = MeshNetworkManager.bearer.proxies.first{
            if let connectNode = selectNodes.first(where: {$0.nodeuuidString == bearer.nodeUUID}) { //找到直连的设备
                KLMLog("uuid = \(connectNode.nodeuuidString)")
                selectNodes.remove(connectNode)
                selectNodes.append(connectNode)
            }
            
            //复位设备
            resetCurrentNode()
            
        } else {
            SVProgressHUD.showInfo(withStatus: "APP与设备没有蓝牙连接")
        }
    }
    
    private func resetCurrentNode() {
        KLMLog("currentIndex = \(currentIndex)")
        SVProgressHUD.show(withStatus: "复位中")
        if currentIndex > selectNodes.count - 1 {
            SVProgressHUD.showInfo(withStatus: "重置完成")
            selectNodes.removeAll()
            tableView.reloadData()
            return
        }
        KLMSmartNode.sharedInstacnce.resetNode(node: selectNodes[currentIndex])
    }
    
    @IBAction func bottomClick(_ sender: Any) {
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        if selectNodes.isEmpty {
            SVProgressHUD.showInfo(withStatus: "请选择设备")
            return
        }
        
        if isFromImage {
            
            let vc = KLMCheckImagesViewController()
            vc.nodes = selectNodes
            navigationController?.pushViewController(vc, animated: true)
            
        } else {
            
            resetNodes()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.nodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let node = self.nodes[indexPath.row]
        if let index = selectNodes.firstIndex(where: {$0.uuid == node.uuid}) {
            selectNodes.remove(at: index)
            tableView.reloadData()
        } else {
            
            if selectNodes.count >= 20 {
                
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

extension KLMSelectNodesViewController: KLMSmartNodeDelegate {
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode) {
        
        if let index = nodes.firstIndex(where: {$0.uuid == manager.currentNode?.uuid}) {
            nodes.remove(at: index)
            let indexPath = IndexPath.init(row: index, section: 0)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        currentIndex+=1
        resetCurrentNode()
        
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        
        NotificationCenter.default.post(name: .deviceReset, object: nil)
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        
        KLMShowError(error)
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            self.currentIndex+=1
            self.resetCurrentNode()
        }
    }
}
