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
    var selectNodes: [Node] = [Node]()
    var currentIndex: Int = 0
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMMessageManager.sharedInstacnce.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("unGroup")
        
        tableView.separatorStyle = .none
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
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
        if selectNodes.isEmpty {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please select devices"))
            return
        }
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        next()
        
    }
    
    private func next() {
        
        if currentIndex >= selectNodes.count { ///全部添加完成
            
            ///提交数据到服务器
            if KLMMesh.save() {
                
            }

            NotificationCenter.default.post(name: .deviceAddToGroup, object: nil)
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            self.navigationController?.popViewController(animated: true)
            
            return
        }
        
        let selectNode = selectNodes[currentIndex]
        KLMMessageManager.sharedInstacnce.addNodeToGroup(withNode: selectNode, withGroup: KLMHomeManager.currentGroup)
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
        
        if selectNodes.count >= 3 {
            
            SVProgressHUD.showInfo(withStatus: String.init(format: LANGLOC("Select at most %d lights"), selectNodes.count))
            return
        }
        
        let node = self.nodes[indexPath.row]
        if let index = selectNodes.firstIndex(where: {$0.uuid == node.uuid}) {
            selectNodes.remove(at: index)
            tableView.reloadData()
        } else {
            
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

extension KLMGroupDeviceAddTableViewController: KLMMessageManagerDelegate {
    
    
    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {
        
        currentIndex += 1
        next()
//        if error != nil { //失败
//
//            next()
////            SVProgressHUD.showInfo(withStatus: error?.message)
//            return
//        }
    
    }
    
}

extension KLMGroupDeviceAddTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
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
