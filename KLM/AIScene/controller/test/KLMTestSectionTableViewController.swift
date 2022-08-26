//
//  KLMTestSectionTableViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/25.
//

import UIKit

class KLMTestSectionTableViewController: UITableViewController {

    var BLEVersion: String = "获取失败"
    lazy var resetBtn: UIButton = {
        let resetBtn = UIButton.init()
        resetBtn.frame = CGRect.init(x: KLMScreenW - 10 - 50, y: 10, width: 50, height: 30)
        resetBtn.setTitle("复位", for: .normal)
        resetBtn.setTitleColor(.black, for: .normal)
        resetBtn.layer.borderWidth = 1
        resetBtn.layer.borderColor = UIColor.black.cgColor
        resetBtn.addTarget(self, action: #selector(reset), for: .touchUpInside)
        return resetBtn
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        checkBleVersion()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.rowHeight = 50
        
        sendFlash()
    }
    
    //灯闪烁
    func sendFlash() {
        
        let parame = parameModel(dp: .flash, value: 1)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    private func checkBleVersion() {
        
        SVProgressHUD.show()
        let parame = parameModel(dp: .deviceSetting)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @objc func reset() {
        
        SVProgressHUD.show()
        KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 7
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "版本号：  \(BLEVersion)"
            cell.contentView.addSubview(resetBtn)
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "PCBA测试"
        } else if indexPath.row == 2 {
            cell.textLabel?.text = "驱动测试"
        } else if indexPath.row == 3 {
            cell.textLabel?.text = "成品测试"
        } else if indexPath.row == 4 {
            cell.textLabel?.text = "老化测试"
        } else if indexPath.row == 5 {
            cell.textLabel?.text = "包装测试"
        } else if indexPath.row == 6 {
            cell.textLabel?.text = "硬件信息查询"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            
            let vc = KLMPCBASensorViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        } else if indexPath.row == 2 {
           
            let vc = KLMQudongTestViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        } else if indexPath.row == 3 {
            
            let vc = KLMChengpinViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        } else if indexPath.row == 4{
            
            let vc = KLMLaoHuaTestViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        } else if indexPath.row == 5{
            
            let vc = KLMBaoZhuangTestViewController()
            navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.row == 6{
            
            let vc = KLMTestVersionViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}

extension KLMTestSectionTableViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .deviceSetting, let value = message?.value as? [UInt8] {
            SVProgressHUD.dismiss()
            /// 版本 0112  显示 1.1.2
            let version = value[0...1]
            let first: Int = Int(version[0])
            let second: Int = Int((version[1] & 0xf0) >> 4)
            let third: Int =  Int(version[1] & 0x0f)
            BLEVersion = "\(first).\(second).\(third)"
            self.tableView.reloadData()
        }
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        SVProgressHUD.showSuccess(withStatus: "复位成功")
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            NotificationCenter.default.post(name: .deviceReset, object: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

