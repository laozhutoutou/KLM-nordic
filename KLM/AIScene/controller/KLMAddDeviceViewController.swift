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
    rssi: Int
)

class KLMAddDeviceViewController: UIViewController {
    

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var searchView: KLMDeviceSearchView!
    var emptyView: KLMSearchDeviceEmptyView!
    
    var deviceName = ""
    
    var isHaveDevice: Bool = false
    
    var messageTimer: Timer?
    ///超时时间
    var messageTimeout: Int = 20
    ///当前秒
    var currentTime: Int = 0
    
    deinit {
        
        KLMSIGMeshManager.sharedInstacnce.stopScanning()
    }
    
    private var discoveredPeripherals: [DiscoveredPeripheral] = []
    private var selectedDevice: UnprovisionedDevice?
    private var alert: UIAlertController?
    
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

        navigationItem.title = LANGLOC("addDevice")
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
        
    }
    
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
        
        self.isHaveDevice = true
        
        contentView.isHidden = false
        searchView.isHidden = true
    }
    
    func searchDevice() {
        
        //开始计时
        startTime()
        
        discoveredPeripherals.removeAll()
        self.tableView.reloadData()
        
        isHaveDevice = false
        contentView.isHidden = true
        searchView.isHidden = false
        
        KLMSIGMeshManager.sharedInstacnce.startScan(scanType: .ScanForUnprovision)
        
    }
    
    //连接设备
    func connectDevice(model: DiscoveredPeripheral) {
        
        ///没网不能添加设备
        if KLMHomeManager.sharedInstacnce.networkStatus == .NetworkStatusNotReachable {
            SVProgressHUD.showError(withStatus: LANGLOC("NetWorkTip"))
            return
        }
        
        SVProgressHUD.show(withStatus: "Connecting...")
        SVProgressHUD.setDefaultMaskType(.black)
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
            
            if self.isHaveDevice == false { //没有设备

                self.noFoundDevice()
            }
        }
    }
}

extension KLMAddDeviceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return discoveredPeripherals.count

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 80
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let discoveredPeripheral = discoveredPeripherals[indexPath.row]
        let cell = KLMDeviceAddCell.cellWithTableView(tableView: tableView)
        cell.model = discoveredPeripheral
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
        
        isHaveDevice = true
        
        if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == device.peripheral }) {
            discoveredPeripherals[index] = device
            tableView.reloadData()
        } else {
            foundDevice()
            discoveredPeripherals.append(device)
            tableView.insertRows(at: [IndexPath(row: discoveredPeripherals.count - 1, section: 0)], with: .fade)
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
        let vc = CMDeviceNamePopViewController()
        vc.titleName = LANGLOC("Light")
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.nameBlock = { [weak self] name in

            guard let self = self else { return }
            self.deviceName = name
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
        SVProgressHUD.showSuccess(withStatus: LANGLOC("connectSuccess"))
        
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
        
        //正式APP
        device.name = self.deviceName
        if KLMMesh.save() {
            
            //刷新首页
            NotificationCenter.default.post(name: .deviceAddSuccess, object: nil)

            //跳转页面
            DispatchQueue.main.asyncAfter(deadline: 0.5){

                let vc = KLMDeviceEditViewController()
//                vc.isFromDeviceAdd = true
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?) {
        
        KLMShowError(error)
        
    }
}

