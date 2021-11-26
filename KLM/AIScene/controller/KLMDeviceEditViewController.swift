//
//  KLMDeviceEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit
import nRFMeshProvision
import SVProgressHUD

private enum itemType: Int, CaseIterable {
    case lightPower = 0
    case lightSetting
    case CMOS
    case motion
    case test
    case DFU
    case rename
    case group
    case reset
    case sigleControl
    case downLoadPic
}

class KLMDeviceEditViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var nameLab: UILabel!
    
    var deviceGroups = [Group]()
    
    //1 打开
    var cameraSwitch = 1
    //灯开关
    var lightSwitch = 0
    
    ///版本号
    var MCUVersion: Int?
    var BLEVersion: Int?
    
    var BLEVersionData: KLMVersion.KLMVersionData?
    var MCUVersionData: KLMVersion.KLMVersionData?

    //节能开关
    var motionValue: Bool = false
    //颜色测试
    var colorTest: Bool  = false
    ///是否来自设备添加页面
    var isFromDeviceAdd = false
    var isVersionFirst = true
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        setupNodeMessage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        event()
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkGroup), name: .deviceAddToGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupNodeMessage), name: .refreshDeviceEdit, object: nil)
        
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
        
        checkVerison()
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
            let parameTime = parameModel(dp: .AllDp)
            KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
        }

    }
    
    func checkVerison() {
        
        KLMService.checkVersion(type: "bluetooth") { response in
            self.BLEVersionData = response as? KLMVersion.KLMVersionData
            self.tableView.reloadData()
            self.showUpdateView()
        } failure: { error in
            
        }
        
        KLMService.checkVersion(type: "mcu") { response in
            self.MCUVersionData = response as? KLMVersion.KLMVersionData
            self.tableView.reloadData()
            self.showUpdateView()
        } failure: { error in
            
        }
    }
    
    func showUpdateView() {
        
        if isFromDeviceAdd && isVersionFirst {
            
            guard let bleData = self.BLEVersionData, let mcuData = self.MCUVersionData,
                  let bleV = BLEVersion, let mcuV = MCUVersion else {
                
                return
            }
            
            isVersionFirst = false
            
            let currentVersion: String = "\(bleV).\(mcuV)"
            //最新版本 -- 服务器查询
            let newestVersion: String = bleData.fileVersion + "." + mcuData.fileVersion
            
            let value = currentVersion.compare(newestVersion)
            if value == .orderedAscending {//左操作数小于右操作数，需要升级
                
                ///更新消息
                var updateMsg: String = bleData.englishMessage + "," + mcuData.englishMessage
                if Bundle.isChineseLanguage() {///使用中文
                    updateMsg =  bleData.updateMessage + "," + mcuData.updateMessage
                }
                
                ///弹出更新框
                let vc = UIAlertController.init(title: LANGLOC("Softwareupdate"), message: "V \(newestVersion)\n\(updateMsg)", preferredStyle: .alert)
                vc.addAction(UIAlertAction.init(title: LANGLOC("Update"), style: .destructive, handler: { action in
                    
                    let vc = KLMDFUViewController()
                    vc.BLEVersion = bleV
                    vc.MCUVersion = mcuV
                    vc.BLEVersionData = bleData
                    vc.MCUVersionData = mcuData
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                }))
                present(vc, animated: true, completion: nil)
                
            }
        }
    }
}

extension KLMDeviceEditViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp ==  .cameraPower{
            
            let value = message?.value as! Int
            self.cameraSwitch = value
            self.tableView.reloadData()
            
        }
        
        if message?.dp ==  .checkVersion, let value = message?.value as? String {//查询版本
            
            //0100  01蓝牙  00mcu
            let BLE: Int = Int(value.substring(to: 2).hexadecimalToDecimal())!
            BLEVersion = BLE
            
            //
            let MCU: Int = Int(value.substring(from: 2).hexadecimalToDecimal())!
            MCUVersion = MCU
            
            self.showUpdateView()
            self.tableView.reloadData()
        }
        
        if message?.dp ==  .motionPower{
            let value = message?.value as! Int
            self.motionValue = value == 0 ? false : true
            self.tableView.reloadData()
        }
        
        if message?.dp ==  .colorTest{
            
            let value = message?.value as! Int
            self.colorTest = value == 2 ? false : true
            self.tableView.reloadData()
        }
        if message?.dp ==  .power{
            
            let value = message?.value as! Int
            self.lightSwitch = value
            self.tableView.reloadData()
        }
        
        KLMLog("success")
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
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

extension KLMDeviceEditViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        case itemType.CMOS.rawValue:
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
        case itemType.DFU.rawValue://MCU
            ///1.1 代表蓝牙版本是1，MCU版本是1，蓝牙在前面
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Software")
            cell.rightTitle = LANGLOC("Version ") + "\(BLEVersion ?? 0).\(MCUVersion ?? 0)"
            return cell
        case itemType.test.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Devicecoloursensing") + LANGLOC("Test")
            cell.rightTitle = self.colorTest == false ? LANGLOC("OFF") : LANGLOC("ON")
            return cell
        case itemType.group.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("groupSetting")
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
        case itemType.sigleControl.rawValue://
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = "单独控制"
            cell.rightTitle = ""
            return cell
        case itemType.downLoadPic.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = "下载图像"
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
            KLMPhotoManager().photoAuthStatus { [weak self] in
                guard let self = self else { return }
                
                let vc = KLMImagePickerController()
                vc.sourceType = UIImagePickerController.SourceType.camera
                self.tabBarController?.present(vc, animated: true, completion: nil)
                
            }
            
        case itemType.motion.rawValue:
            let vc = KLMMotionViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.reset.rawValue: //恢复出厂设置
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            let vc = UIAlertController.init(title: LANGLOC("restorefactorysettings"), message: nil, preferredStyle: .actionSheet)
            vc.addAction(UIAlertAction.init(title: LANGLOC("Reset"), style: .destructive, handler: { action in
                SVProgressHUD.show()
                KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)

            }))
            vc.addAction(UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil))
            present(vc, animated: true, completion: nil)
        case itemType.DFU.rawValue:///固件更新
            //当前版本
            
            guard let bleData = self.BLEVersionData, let mcuData = self.MCUVersionData else {
                SVProgressHUD.showInfo(withStatus: "Check version failed")
                return
            }
            guard let bleV = BLEVersion, let mcuV = MCUVersion else {
                SVProgressHUD.showInfo(withStatus: "Check version failed")
                return
            }
            let currentVersion: String = "\(bleV).\(mcuV)"
            //最新版本 -- 服务器查询
            let newestVersion: String = bleData.fileVersion + "." + mcuData.fileVersion
            
            let value = currentVersion.compare(newestVersion)
            if value == .orderedAscending {//左操作数小于右操作数，需要升级
                
                let vc = KLMDFUViewController()
                vc.BLEVersion = bleV
                vc.MCUVersion = mcuV
                vc.BLEVersionData = bleData
                vc.MCUVersionData = mcuData
                
                navigationController?.pushViewController(vc, animated: true)
                
            } else {
                
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
            }
        case itemType.sigleControl.rawValue://六路测试
            let vc = KLMTestViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.test.rawValue:
            let vc = KLMText1ViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.downLoadPic.rawValue:
            let vc = KLMTestCameraViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            
            break
        }
    }
}
