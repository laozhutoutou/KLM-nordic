//
//  KLMDeviceEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit
import nRFMeshProvision

private enum itemType: Int, CaseIterable {
    case lightPower = 0
    case lightSetting
    case CMOS
    case motion
    case DFU
    case rename
    case group
    case reset
//    case sigleControl //单路控制
    case downLoadPic //下载图像
//    case passengerFlow //客流统计
    
}

class KLMDeviceEditViewController: UIViewController, Editable {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var nameLab: UILabel!
    
    var deviceGroups: [Group] = [Group]()
    
    //1 打开 颜色识别
    var cameraSwitch = 1
    //灯开关
    var lightSwitch = 0
    
    ///蓝牙固件版本号
    var BLEVersion: String?
    ///服务器上的版本
    var BLEVersionData: KLMVersion.KLMVersionData?

    //节能开关
    var motionValue: Bool = false
    //颜色测试
    var colorTest: Bool  = false
 
    var isVersionFirst = true
    
    //来自设备添加
    var isFromAddDevice: Bool = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        checkVerison()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        event()
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkGroup), name: .deviceAddToGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupNodeMessage), name: .refreshDeviceEdit, object: nil)
        
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
    }
    
    func event() {
        
        checkGroup()
        
        sendFlash()
        
        ///语音
        //添加手势
        let tap: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tap))
        tap.numberOfTapsRequired = 3
        contentView.addGestureRecognizer(tap)
    }
    
    //灯闪烁
    func sendFlash() {
        
        let parame = parameModel(dp: .flash, value: 2)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    ///查询设备所属分组
    @objc func checkGroup() {
        deviceGroups = KLMHomeManager.currentModel.subscriptions
        self.tableView.reloadData()
    }
    
    @objc func setupNodeMessage() {
        
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            
            //获取状态
            let parame = parameModel(dp: .deviceSetting)
            KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
        }

    }
    
    func checkVerison() {
        
        KLMService.checkBlueToothVersion { response in
            self.BLEVersionData = response as? KLMVersion.KLMVersionData
            self.tableView.reloadData()
            self.setupNodeMessage()
        } failure: { error in
            self.setupNodeMessage()
        }
    }
    
    func showUpdateView() {
    
        guard let bleData = self.BLEVersionData,
              let bleV = BLEVersion else {
            
            return
        }
        
        if isVersionFirst {
            isVersionFirst = false
            KLMTool.checkBluetoothVersion(newestVersion: bleData, bleversion: bleV, viewController: self) {
                
                if bleData.isForceUpdate {
                    self.isVersionFirst = true
                }
                let vc = KLMDFUTestViewController()
                vc.BLEVersionData = bleData
                self.navigationController?.pushViewController(vc, animated: true)
                
            } cancel: {
                if bleData.isForceUpdate {
                    self.navigationController?.popViewController(animated: true)
                } else { //普通升级
                    //弹框
                    if self.isFromAddDevice {
                        if KLMHomeManager.currentNode.noCamera == true {
                            return
                        }
                        let vc = UIAlertController.init(title: LANGLOC("View Commodity position right now？"), message: LANGLOC("To obtain the best lighting, please direct the center of light beam at commodity. View Commodity position righ now, or view it later."), preferredStyle: .alert)
                        vc.addAction(UIAlertAction.init(title: LANGLOC("Right now"), style: .default, handler: { action in
                            
                            let vc = KLMPicDownloadViewController()
                            self.navigationController?.pushViewController(vc, animated: true)
                        }))
                        vc.addAction(UIAlertAction.init(title: LANGLOC("Later"), style: .cancel, handler: { action in

                        }))
                        self.present(vc, animated: true)
                    }
                }
            } noNeedUpdate: { //不需要升级
                
                if self.isFromAddDevice {
                    if KLMHomeManager.currentNode.noCamera == true {
                        return
                    }
                    let vc = UIAlertController.init(title: LANGLOC("View Commodity position right now？"), message: LANGLOC("To obtain the best lighting, please direct the center of light beam at commodity. View Commodity position righ now, or view it later."), preferredStyle: .alert)
                    vc.addAction(UIAlertAction.init(title: LANGLOC("Right now"), style: .default, handler: { action in
                        
                        let vc = KLMPicDownloadViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                    }))
                    vc.addAction(UIAlertAction.init(title: LANGLOC("Later"), style: .cancel, handler: { action in
                    }))
                    self.present(vc, animated: true)
                }
            }
        }
    }
    
    @objc func tap() {
        
        KLMLog("连续点击")
        if cameraSwitch != 1 { //自动颜色开关没打开
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please turn on ") + LANGLOC("Auto Mode"))
            return
        }
        let vc = KLMAudioViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension KLMDeviceEditViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        ///版本号2字节，开关1，颜色识别1，motion 3（开关，亮度，时间）
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
            
            ///颜色识别
            let cmos: Int = Int(value[3])
            self.cameraSwitch = cmos
            
            ///节能
            let motion: Int = Int(value[4])
            self.motionValue = motion == 0 ? false : true
            
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
        ///从拍照页面返回来，如果灯是关闭的，不提示开灯操作
        if error?.dp == .recipe {
            return
        }
        KLMShowError(error)
    }
}

extension KLMDeviceEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return itemType.allCases.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if KLMHomeManager.currentNode.noCamera == true {
            switch indexPath.row {
            case itemType.CMOS.rawValue,
                itemType.motion.rawValue,
                itemType.downLoadPic.rawValue:
                return 0
            default:
                break
            }
        }
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
        case itemType.CMOS.rawValue://颜色识别
            let cell: KLMOneSwitchCell = KLMOneSwitchCell.cellWithTableView(tableView: tableView)
            cell.cameraOnOff = self.cameraSwitch
            return cell
        case itemType.motion.rawValue://节能设置
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Energysavingsettings")
            cell.rightTitle = self.motionValue == false ? LANGLOC("OFF") : LANGLOC("ON")
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
        case itemType.DFU.rawValue://
            ///
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Software")
            cell.rightTitle = LANGLOC("Version") + " " + (BLEVersion ?? "0")
            return cell
        case itemType.group.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Group setting")
            if self.deviceGroups.count <= 0 {
                let string = LANGLOC("unGroup")
                cell.rightTitle = string
            } else {
                var string = ""
                for model in self.deviceGroups {
                    
                    string = string + model.name + "，"
                    
                }
                string.removeLast()
                cell.rightTitle = string
            }
            return cell
//        case itemType.sigleControl.rawValue://
//            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
//            cell.isShowLeftImage = false
//            cell.leftTitle = "单路控制"
//            cell.rightTitle = ""
//            return cell
        case itemType.downLoadPic.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("View commodity position")
            cell.rightTitle = ""
            return cell
//        case itemType.passengerFlow.rawValue:
//            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
//            cell.isShowLeftImage = false
//            cell.leftTitle = LANGLOC("Customer Counting")
//            cell.rightTitle = ""
//            return cell
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
                
                KLMHomeManager.currentNode.name = name
                
                if KLMMesh.save() {
                    
                    self.nameLab.text = KLMHomeManager.currentNode.name
                    self.tableView.reloadData()
                }
                
                //发送通知更新首页
                NotificationCenter.default.post(name: .deviceNameUpdate, object: nil)
                
            }
            present(vc, animated: true, completion: nil)
            
        case itemType.group.rawValue://分组
            let vc = KLMGroupDeviceAddToViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        case itemType.lightSetting.rawValue://灯光设置
            //是否有相机权限
//            KLMPhotoManager().photoAuthStatus { [weak self] in
//                guard let self = self else { return }
//
//                let vc = KLMImagePickerController()
//                vc.sourceType = .camera
//                self.present(vc, animated: true, completion: nil)
//
//            }
            let vc = KLMLightSettingController()
            navigationController?.pushViewController(vc, animated: true)
            
        case itemType.motion.rawValue:
            let vc = KLMMotionViewController()
            let nav = KLMNavigationViewController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
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
        case itemType.DFU.rawValue:///固件更新
            
            guard let bleData = self.BLEVersionData else {
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
                return
            }
            guard let bleV = BLEVersion else {
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
                return
            }

            let value = bleV.compare(bleData.fileVersion)
            if value == .orderedAscending {//左操作数小于右操作数，需要升级
                
                let vc = KLMDFUTestViewController()
                vc.BLEVersionData = bleData
                navigationController?.pushViewController(vc, animated: true)

            } else {
                 
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
            }
        case itemType.CMOS.rawValue:
            if cameraSwitch != 1 { //自动颜色开关没打开
                SVProgressHUD.showInfo(withStatus: LANGLOC("Please turn on ") + LANGLOC("Auto Mode"))
                return
            }
            let vc = KLMCMOSViewController()
            navigationController?.pushViewController(vc, animated: true)
            
//        case itemType.sigleControl.rawValue://六路测试
//            let vc = KLMTestViewController()
//            navigationController?.pushViewController(vc, animated: true)
        case itemType.downLoadPic.rawValue:
            
            let vc = KLMPicDownloadViewController()
            navigationController?.pushViewController(vc, animated: true)
            
//            let vc = KLMRGBTestViewController()
//            navigationController?.pushViewController(vc, animated: true)
//            let vc = KLMTestCameraViewController()
//            navigationController?.pushViewController(vc, animated: true)
//        case itemType.passengerFlow.rawValue:
//            let vc = KLMPassengerFlowViewController()
//            navigationController?.pushViewController(vc, animated: true)
        default:
            
            break
        }
    }
}
