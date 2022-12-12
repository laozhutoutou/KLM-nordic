//
//  KLMControllerSettingViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/15.
//

import UIKit
import nRFMeshProvision

private enum itemType: Int, CaseIterable {
  
    case lightPower = 0
    case lightSetting
    case DFU
    case rename
//    case group
    case reset
}

class KLMControllerSettingViewController: UIViewController, Editable {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nameLab: UILabel!
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    private var lightSwitch = 0
    
    ///蓝牙固件版本号
    private var BLEVersion: String?
    ///服务器上的版本
    private var BLEVersionData: KLMVersion.KLMVersionData?
    ///子版本号
    private var newVersion: String?
    
    private var isVersionFirst = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        checkVerison()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        event()
        
        ///显示空白页面
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 5) {
            self.hideEmptyView()
        }
    }
    
    func setupUI() {
        
        self.navigationItem.title = LANGLOC("setting")
        nameLab.text = KLMHomeManager.currentNode.nodeName
        
        view.backgroundColor = appBackGroupColor
        tableView.backgroundColor = appBackGroupColor
        
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        
        iconImageView.image = UIImage.init(named: KLMHomeManager.currentNode.icon)
    }
    
    func event() {
        
        
    }
    
    private func checkVerison() {
        
        KLMService.checkNewHardwareVersion { response in
            
            self.BLEVersionData = response as? KLMVersion.KLMVersionData
            if let BB = self.BLEVersionData {
                
                var newVersion: String?
                let jsonData: KLMSubVersion = KLMTool.jsonToModel(BB.jsonData, KLMSubVersion.self) as! KLMSubVersion
                if KLMHomeManager.currentNode.deviceType == .qieXiang {
                    newVersion = jsonData.qieXiang
                } else if KLMHomeManager.currentNode.deviceType == .RGBControl {
                    newVersion = jsonData.RGBControl
                } else if KLMHomeManager.currentNode.deviceType == .Dali {
                    newVersion = jsonData.Dali
                }
                self.newVersion = newVersion
            }
            
            self.tableView.reloadData()
            self.setupNodeMessage()
            
        } failure: { error in
            
            self.setupNodeMessage()
        }
    }
    
    func setupNodeMessage() {
        
        let parame = parameModel(dp: .deviceSetting)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    func showUpdateView() {
        
        guard let bleData = self.BLEVersionData, let newVersion = self.newVersion,
              let bleV = self.BLEVersion else {
            
            return
        }
                
        if isVersionFirst {
            isVersionFirst = false
            
            KLMTool.checkBluetoothVersion(newestVersion: newVersion, bleversion: bleV, EnMessage: bleData.englishMessage, CNMessage: bleData.updateMessage, viewController: self) {
                
                if bleData.isForceUpdate {
                    self.isVersionFirst = true
                }
                let vc = KLMTLWOTAViewController()
                vc.BLEVersionData = bleData
                self.navigationController?.pushViewController(vc, animated: true)
                
            } cancel: {
                if bleData.isForceUpdate {
                    self.navigationController?.popViewController(animated: true)
                }
            } noNeedUpdate: { //不需要升级
                
            }
        }
    }

}

extension KLMControllerSettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return itemType.allCases.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        
        return 56
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
            
        case itemType.lightPower.rawValue:///灯开关
            let cell: KLMLightOnOffCell = KLMLightOnOffCell.cellWithTableView(tableView: tableView)
            cell.onOff = self.lightSwitch
            return cell
        case itemType.lightSetting.rawValue:
            
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("lightSet")
            cell.rightTitle = ""
            return cell
        case itemType.DFU.rawValue://
            ///
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Software")
            cell.rightTitle = LANGLOC("Version") + " " + (BLEVersion ?? "0")
            return cell
        case itemType.rename.rawValue:
            
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("reName")
            cell.rightTitle = KLMHomeManager.currentNode.nodeName
            return cell
        
        case itemType.reset.rawValue://恢复出厂设置
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("restorefactorysettings")
            cell.rightTitle = ""
            return cell

        default:
            break
        }
        
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case itemType.rename.rawValue://设备名称
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            let vc = CMDeviceNamePopViewController()
            vc.titleName = LANGLOC("Light")
            vc.text = KLMHomeManager.currentNode.name
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.nameBlock = {[weak self] name in
                guard let self = self else { return }
                
                if let network = MeshNetworkManager.instance.meshNetwork {
                    
                    let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
                    if notConfiguredNodes.contains(where: {$0.name == name}) {
                        SVProgressHUD.showInfo(withStatus: LANGLOC("The name already exists"))
                        return
                    }
                }
                
                KLMHomeManager.currentNode.name = name
                
                if KLMMesh.save() {
                    
                    self.nameLab.text = KLMHomeManager.currentNode.name
                    self.tableView.reloadData()
                }
                
                //发送通知更新首页
                NotificationCenter.default.post(name: .deviceNameUpdate, object: nil)
                
            }
            present(vc, animated: true, completion: nil)
                        
        case itemType.lightSetting.rawValue://灯光设置
            
            let vc = KLMControllerOperationViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.DFU.rawValue:///固件更新
            
            guard let bleData = self.BLEVersionData, let newVersion = newVersion else {
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
                return
            }
            guard let bleV = BLEVersion else {
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
                return
            }

            let value = bleV.compare(newVersion)
            if value == .orderedAscending {//左操作数小于右操作数，需要升级
                
                let vc = KLMTLWOTAViewController()
                vc.BLEVersionData = bleData
                navigationController?.pushViewController(vc, animated: true)

            } else {
                 
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
            }
        case itemType.reset.rawValue: //恢复出厂设置
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            let vc = UIAlertController.init(title: LANGLOC("restorefactorysettings"), message: nil, preferredStyle: .alert)
            vc.addAction(UIAlertAction.init(title: LANGLOC("Reset"), style: .default, handler: { action in
                SVProgressHUD.show()
                KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)

            }))
            vc.addAction(UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil))
            present(vc, animated: true, completion: nil)
        default:
            
            break
        }
    }
}

extension KLMControllerSettingViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .deviceSetting, let value = message?.value as? [UInt8] {
            SVProgressHUD.dismiss()
            /// 版本 0112  显示 1.1.2
            let version = value[0...1]
            let first: Int = Int(version[0])
            let second: Int = Int((version[1] & 0xf0) >> 4)
            let third: Int =  Int(version[1] & 0x0f)
            BLEVersion = "\(first).\(second).\(third)"
            self.showUpdateView()
            
            ///开关
            let power: Int = Int(value[2])
            self.lightSwitch = power
            
            ///刷新页面
            self.tableView.reloadData()
            ///隐藏显示框
            self.hideEmptyView()
        }
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode) {
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        
        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
        NotificationCenter.default.post(name: .deviceReset, object: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        
        KLMShowError(error)
    }
}
