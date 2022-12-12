//
//  KLMLightSettingController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/30.
//

import UIKit

private enum itemType: Int, CaseIterable {
    case picture = 0
    case custome
    case light
}

class KLMLightSettingController: UITableViewController {
    
    ///蓝牙固件版本号
    private var BLEVersion: String?
    ///服务器上的版本
    private var BLEVersionData: KLMVersion.KLMVersionData?
    private var isVersionFirst = true
    
    ///需要闪灯
    var isNeedFrash: Bool = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {
            
            KLMSmartNode.sharedInstacnce.delegate = self
            self.checkNetworkVersion()
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("lightSet")
        tableView.rowHeight = 50
        tableView.separatorStyle = .none
        
        ///发送闪灯
        if isNeedFrash {
            sendFlash()
        }
    }
    
    //灯闪烁
    private func sendFlash() {
        
        let parame = parameModel(dp: .flash, value: 2)
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {

            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

        } else if KLMHomeManager.sharedInstacnce.controllType == .Group {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in 

            } failure: { error in

            }
        }
    }
    
    private func checkBleVersion() {
        
        let parame = parameModel(dp: .deviceSetting)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    private func checkNetworkVersion() {
        
        if KLMHomeManager.currentNode.deviceType == .noCamera { ///没有摄像头
            KLMService.checkTLWVersion { response in
                
                self.BLEVersionData = response as? KLMVersion.KLMVersionData
                self.checkBleVersion()
                
            } failure: { error in
                
                self.checkBleVersion()
            }

        } else {
            
            KLMService.checkBlueToothVersion { response in
                self.BLEVersionData = response as? KLMVersion.KLMVersionData
                self.checkBleVersion()
            } failure: { error in
                self.checkBleVersion()
            }
        }
    }
    
    private func showUpdateView() {
        
        guard let bleData = self.BLEVersionData,
              let bleV = BLEVersion else {
            
            return
        }
        
        if isVersionFirst {
            
            KLMTool.checkBluetoothVersion(newestVersion: bleData.fileVersion, bleversion: bleV, EnMessage: bleData.englishMessage, CNMessage: bleData.updateMessage, viewController: self) {
                
                if KLMHomeManager.currentNode.deviceType == .noCamera {
                    
                    let vc = KLMTLWOTAViewController()
                    vc.isPresent = true
                    vc.BLEVersionData = bleData
                    let nav = KLMNavigationViewController.init(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true)
                    return
                }
                
                let vc = KLMDFUTestViewController()
                vc.isPresent = true
                vc.BLEVersionData = bleData
                let nav = KLMNavigationViewController.init(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
                
            } cancel: {
                if bleData.isForceUpdate {
                    self.dismiss(animated: true)
                }
            } noNeedUpdate: {
                
            }

        }
        
        if bleData.isForceUpdate { //强制更新，每次都弹框
            
        } else { //普通更新，只弹框一次
            isVersionFirst = false
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return itemType.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        switch indexPath.row {
        case itemType.picture.rawValue:
            cell.leftTitle = LANGLOC("Take a picture")
        case itemType.custome.rawValue:
            cell.leftTitle = LANGLOC("custom")
        case itemType.light.rawValue:
            cell.leftTitle = LANGLOC("Brightness")
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case itemType.picture.rawValue:
            //是否有相机权限
            KLMPhotoManager().photoAuthStatus { [weak self] in
                guard let self = self else { return }
                
                let vc = KLMImagePickerController()
                vc.sourceType = .camera
                self.present(vc, animated: true, completion: nil)
                
            }
        case itemType.custome.rawValue:
            let vc = KLMCustomViewController()
            let nav = KLMNavigationViewController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        case itemType.light.rawValue:
            let vc = KLMBrightnessViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}

extension KLMLightSettingController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .deviceSetting, let value = message?.value as? [UInt8] {
            
            /// 版本 0112  显示 1.1.2
            let version = value[0...1]
            let first: Int = Int(version[0])
            let second: Int = Int((version[1] & 0xf0) >> 4)
            let third: Int =  Int(version[1] & 0x0f)
            BLEVersion = "\(first).\(second).\(third)"
            self.showUpdateView()
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        
    }
}
