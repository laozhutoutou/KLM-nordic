//
//  KLMAddDeviceViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/10.
//

import UIKit
import nRFMeshProvision
import CoreBluetooth

typealias DiscoveredPeripheral = (
    device: UnprovisionedDevice,
    peripheral: CBPeripheral,
    rssi: Int,
    deviceType: nodeDeviceType
)

class KLMAddDeviceViewController: UIViewController {
    

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var searchView: KLMDeviceSearchView!
    var emptyView: KLMSearchDeviceEmptyView!
    
    var deviceName = ""
    var category: Int!
    
    var messageTimer: Timer?
    ///超时时间
    var messageTimeout: Int = 20
    ///当前秒
    var currentTime: Int = 0
    
    var addType: DeviceType!
    
    deinit {
        
        KLMSIGMeshManager.sharedInstacnce.stopScanning()
    }
    
//    private var discoveredPeripherals: [[DiscoveredPeripheral]] = []
    private var highRssiList: [DiscoveredPeripheral] = []
    private var lowRssiList: [DiscoveredPeripheral] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchDevice()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopTime()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Add new device")
        self.contentView.isHidden = true

        //展示搜索页面
        searchView = KLMDeviceSearchView.deviceSearchView(frame: CGRect(x: 0, y: 200, width: KLMScreenW, height: 300))
        self.view.addSubview(searchView)
        
        //空白页面
        emptyView = KLMSearchDeviceEmptyView.init(frame: CGRect.init(x: 0, y: 200, width: KLMScreenW, height: 240))
        emptyView.isHidden = true
        emptyView.researchBlock = {[weak self] in
            guard let self = self else { return }
            
            self.researchDevice()
        }
        self.view.addSubview(emptyView)
        
        KLMSIGMeshManager.sharedInstacnce.delegate = self
        
        contentView.backgroundColor = appBackGroupColor
        view.backgroundColor = appBackGroupColor
        
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        
        //刷新
        let header = KLMRefreshHeader.init {[weak self] in
            guard let self = self else { return }
            self.searchDevice()
        }
        self.tableView.mj_header = header
        
//        discoveredPeripherals = [highRssiList, lowRssiList]
//        discoveredPeripherals.append(highRssiList)
//        discoveredPeripherals.append(lowRssiList)
    }
    
    //重新搜索
    func researchDevice() {
        
        //开始计时
        startTime()
        
        emptyView.isHidden = true
        searchView.isHidden = false
        
        KLMSIGMeshManager.sharedInstacnce.startScan(scanType: .ScanForUnprovision)
        
    }
    
    func noFoundDevice() {
        
        stopTime()
        
        KLMLog("没有发现设备")
        emptyView.isHidden = false
        searchView.isHidden = true
        
        KLMSIGMeshManager.sharedInstacnce.stopScanning()
    }
    
    func foundDevice() {
        
        stopTime()
        
        contentView.isHidden = false
        searchView.isHidden = true
        self.tableView.mj_header?.endRefreshing()
    }
    
    func searchDevice() {
        
        //开始计时
        startTime()
        
        highRssiList.removeAll()
        lowRssiList.removeAll()
        
        self.tableView.reloadData()

        contentView.isHidden = true
        searchView.isHidden = false
        
        KLMSIGMeshManager.sharedInstacnce.startScan(scanType: .ScanForUnprovision)
        
    }
    
    //连接设备
    func connectDevice(model: DiscoveredPeripheral) {
        
        ///没网不能添加设备
//        if KLMHomeManager.sharedInstacnce.networkStatus == .NetworkStatusNotReachable {
//            SVProgressHUD.showInfo(withStatus: LANGLOC("NetWorkTip"))
//            return
//        }
        
        SVProgressHUD.show(withStatus: "Connecting...")
        SVProgressHUD.setDefaultMaskType(.black)
        KLMLog("---------------\(model.device.uuid)")
        KLMSIGMeshManager.sharedInstacnce.startConnect(discoveredPeripheral: model)
    }
    
    //开始计时
    func startTime() {
        
        KLMLog("开始计时")
        stopTime()
        messageTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(UpdateTimer), userInfo: nil, repeats: true)
    }
    
    //停止计时
    func stopTime() {
        KLMLog("停止计时")
        currentTime = 0
        if messageTimer != nil {
            messageTimer?.invalidate()
            messageTimer = nil
        }
    }
    
    @objc func UpdateTimer() {
        KLMLog("计时时间:\(currentTime)")
        currentTime += 1
        if currentTime > messageTimeout {//超时
            KLMLog("时间超时")
            stopTime()
            
            if highRssiList.count == 0 && lowRssiList.count == 0 { //没有设备

                self.noFoundDevice()
            }
        }
    }
}

extension KLMAddDeviceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return highRssiList.count
        }
        return lowRssiList.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 80
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = KLMDeviceAddCell.cellWithTableView(tableView: tableView)
        if indexPath.section == 0 {
            let model = highRssiList[indexPath.row]
            cell.model = model
        } else {
            let model = lowRssiList[indexPath.row]
            cell.model = model
        }
        cell.connectBlock = {[weak self] M in

            guard let self = self else { return }

            self.connectDevice(model: M)

        }

        return cell
        
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}

extension KLMAddDeviceViewController: KLMSIGMeshManagerDelegate {
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didScanedDevice device: DiscoveredPeripheral) {
        
        if let index = highRssiList.firstIndex(where: { $0.peripheral == device.peripheral }) {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? KLMDeviceAddCell {
                cell.updateRssi(device.rssi)
            }
            return
        }
        
        if let index = lowRssiList.firstIndex(where: { $0.peripheral == device.peripheral }) {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 1)) as? KLMDeviceAddCell {
                cell.updateRssi(device.rssi)
            }
            return
        }
        switch device.deviceType {
        case .qieXiang,
                .RGBControl,
                .Dali:
            if addType == .deviceTypeController {
                foundDevice()
                if device.rssi > -70 {
                    highRssiList.append(device)
                    tableView.insertRows(at: [IndexPath(row: highRssiList.count - 1, section: 0)], with: .fade)
                } else {
                    lowRssiList.append(device)
                    tableView.insertRows(at: [IndexPath(row: lowRssiList.count - 1, section: 1)], with: .fade)
                }
            }
            
        default:
            if addType == .deviceTypeLight {
                foundDevice()
                if device.rssi > -70 {
                    highRssiList.append(device)
                    tableView.insertRows(at: [IndexPath(row: highRssiList.count - 1, section: 0)], with: .fade)
                    
                } else {
                    lowRssiList.append(device)
                    tableView.insertRows(at: [IndexPath(row: lowRssiList.count - 1, section: 1)], with: .fade)
                    
                }
            }
        }
    }
    
    func sigMeshManagerDidConnetctUnprovisionDevice(_ manager: KLMSIGMeshManager) {
        
        SVProgressHUD.dismiss()
        
        if apptype == .test {
            //开始配网
            KLMSIGMeshManager.sharedInstacnce.startActive()
            
            return
        }
        
        ///正式APP
        let vc = KLMDeviceNameAndTypePopViewController()
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        if let network = MeshNetworkManager.instance.meshNetwork {
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            let luminaires = notConfiguredNodes.filter({$0.isTracklight})
            let controllers = notConfiguredNodes.filter({$0.isController})
            if addType == .deviceTypeLight {
                vc.name = "Luminaire\(luminaires.count + 1)"
            } else {
                vc.name = "Controller\(luminaires.count + 1)"
            }
        }
        vc.nameAndTypeBlock = { [weak self] name, type in
            
            guard let self = self else { return }
            self.deviceName = name
            self.category = type
            //开始配网
            KLMSIGMeshManager.sharedInstacnce.startActive()
            
        }
        vc.cancelBlock = {
            
            ///断开连接
            KLMSIGMeshManager.sharedInstacnce.stopConnectDevice()
        }
        present(vc, animated: true, completion: nil)
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node) {
        
        //连接成功
        SVProgressHUD.showSuccess(withStatus: LANGLOC("Connect success"))
        
        //停止
        KLMSIGMeshManager.sharedInstacnce.stopScanning()
        
        //记录当前设备
        KLMHomeManager.sharedInstacnce.smartNode = device
        
        if apptype == .test {
            
            if KLMMesh.save() {
                
                //测试APP
                NotificationCenter.default.post(name: .deviceAddSuccess, object: nil)
                DispatchQueue.main.asyncAfter(deadline: 0.5){

                    let vc = KLMTestSectionTableViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
                
                return
            }
        }
        
        //发送分类指令
        let parame = parameModel(dp: .category, value: self.category!)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
        //正式APP
        device.name = self.deviceName
        
        if KLMMesh.save() {
            
            //修改名称
            KLMService.updateDevice(deviceName: self.deviceName, uuid: device.nodeuuidString) { response in
                
            } failure: { error in
                
            }
            
            //刷新首页
            NotificationCenter.default.post(name: .deviceAddSuccess, object: nil)
            
            if device.isController {
                
                let vc = KLMControllerSettingViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            let vc = KLMDeviceEditViewController()
            vc.isFromAddDevice = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?) {
        
        KLMShowError(error)
        
    }
}

