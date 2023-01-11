//
//  KLMTestSectionTableViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/25.
//

import UIKit

private enum itemType: Int, CaseIterable {
    case version = 0
    case PCBA
    case Qudong
    case Chengpin
    case Laohua
    case Baozhuang
    case checkJiami
    case YingjianTest
    case Yingjian
    case Biaoding
}

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
        
        let parame = parameModel(dp: .flash, value: 2)
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemType.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        switch indexPath.row {
        case itemType.version.rawValue:
            cell.textLabel?.text = "版本号：  \(BLEVersion)"
            cell.contentView.addSubview(resetBtn)
        case itemType.PCBA.rawValue:
            cell.textLabel?.text = "PCBA测试"
        case itemType.Qudong.rawValue:
            cell.textLabel?.text = "驱动测试"
        case itemType.Chengpin.rawValue:
            cell.textLabel?.text = "成品测试"
        case itemType.Laohua.rawValue:
            cell.textLabel?.text = "老化测试"
        case itemType.Baozhuang.rawValue:
            cell.textLabel?.text = "包装测试"
        case itemType.Yingjian.rawValue:
            cell.textLabel?.text = "料号和固件版本查询"
        case itemType.Biaoding.rawValue:
            cell.textLabel?.text = "白平衡标定"
        case itemType.YingjianTest.rawValue:
            cell.textLabel?.text = "硬件信息"
        case itemType.checkJiami.rawValue:
            cell.textLabel?.text = "查询加密状态"
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case itemType.PCBA.rawValue:
            let vc = KLMPCBASensorViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.Qudong.rawValue:
            let vc = KLMQudongTestViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.Chengpin.rawValue:
            let vc = KLMChengpinViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.Laohua.rawValue:
            let vc = KLMLaoHuaTestViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.Baozhuang.rawValue:
            let vc = KLMBaoZhuangTestViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.Yingjian.rawValue:
            let vc = KLMTestVersionViewController()
            vc.BLEVersion = BLEVersion
            navigationController?.pushViewController(vc, animated: true)
        case itemType.Biaoding.rawValue:
            let vc = KLMTestBiaodingViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.YingjianTest.rawValue:
            let vc = KLMTestVersion1ViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.checkJiami.rawValue:
            let vc = KLMCheckVersionTestViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
}

extension KLMTestSectionTableViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp == .deviceSetting, let value = message?.value as? [UInt8] {
            
            /// 版本 0112  显示 1.1.2
            let version = value[0...1]
            let first: Int = Int(version[0])
            let second: Int = Int((version[1] & 0xf0) >> 4)
            let third: Int =  Int(version[1] & 0x0f)
            BLEVersion = "\(first).\(second).\(third)"
            self.tableView.reloadData()
        }
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode) {
        ///提交数据到服务器
        if KLMMesh.save() {
            
            KLMService.deleteDevice(uuid: KLMHomeManager.currentNode.nodeuuidString) { response in
                
            } failure: { error in
                
            }            
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

