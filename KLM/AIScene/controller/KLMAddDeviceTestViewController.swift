//
//  KLMAddDeviceTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/5/17.
//

import UIKit
import nRFMeshProvision

class KLMAddDeviceTestViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    var searchView: KLMDeviceSearchView!
    var emptyView: KLMSearchDeviceEmptyView!
    
    var isHaveDevice: Bool = false
    lazy var timer: KLMTimer = {
        let timer = KLMTimer()
        timer.delegate = self
        return timer
    }()
    
    var totalDevcie: Int = 0 {
        didSet {
            if totalDevcie == selectedDevice.count {
                KLMLog("设备已经完成配网，不管是成功或者失败")
                //刷新首页
                NotificationCenter.default.post(name: .deviceAddSuccess, object: nil)
                DispatchQueue.main.asyncAfter(deadline: 2) {
                    SVProgressHUD.dismiss()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    deinit {
        
        KLMMeshManager.shared.stopScanning()
    }
    
    private var discoveredPeripherals: [DiscoveredPeripheral] = []
    private var selectedDevice: [DiscoveredPeripheral] = [DiscoveredPeripheral]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchDevice()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopTime()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
    }
    
    func setupUI() {
        
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
        
        KLMMeshManager.shared.delegate = self
        
        contentView.backgroundColor = appBackGroupColor
        view.backgroundColor = appBackGroupColor
        
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "添加", target: self, action: #selector(add))
    }
    
    @objc func add() {
        
        if selectedDevice.isEmpty {
            SVProgressHUD.showInfo(withStatus: "请选择设备")
            return
        }
        
        SVProgressHUD.show(withStatus: "Connecting...")
        SVProgressHUD.setDefaultMaskType(.black)
        totalDevcie = 0
        KLMMeshManager.shared.startActive(device: selectedDevice)
    }
    
    func researchDevice() {
        
        //开始计时
        startTime()
        
        emptyView.isHidden = true
        searchView.isHidden = false
        
        KLMMeshManager.shared.startScan()
        
    }
    
    func noFoundDevice() {
        
        stopTime()
        
        KLMLog("没有发现设备")
        emptyView.isHidden = false
        searchView.isHidden = true
        
        KLMMeshManager.shared.stopScanning()
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
        
        KLMMeshManager.shared.startScan()
        
    }
    
    //连接设备
//    func connectDevice(model: DiscoveredPeripheral) {
//
//        ///没网不能添加设备
//        if KLMHomeManager.sharedInstacnce.networkStatus == .NetworkStatusNotReachable {
//            SVProgressHUD.showInfo(withStatus: LANGLOC("NetWorkTip"))
//            return
//        }
//
//        SVProgressHUD.show(withStatus: "Connecting...")
//        SVProgressHUD.setDefaultMaskType(.black)
//        KLMSIGMeshManager.sharedInstacnce.startConnect(discoveredPeripheral: model)
//    }
    
    //开始计时
    private func startTime() {
        
        timer.startTimer(timeOut: 20)
        KLMLog("开始计时")
        
    }
    
    //停止计时
    private func stopTime() {
        KLMLog("停止计时")
        timer.stopTimer()
    }
}

extension KLMAddDeviceTestViewController: KLMTimerDelegate {
    
    func timeDidTimeout(_ timer: KLMTimer) {
        
        if self.isHaveDevice == false { //没有设备

            self.noFoundDevice()
        }
    }
}

extension KLMAddDeviceTestViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return discoveredPeripherals.count

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 80
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let discoveredPeripheral = discoveredPeripherals[indexPath.row]
        let cell = KLMDeviceAddTestCell.cellWithTableView(tableView: tableView)
        cell.model = discoveredPeripheral
        if selectedDevice.contains(where: {$0.peripheral == discoveredPeripheral.peripheral}) {
            cell.isSel = true
        } else {
            cell.isSel = false
        }
        return cell
        
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let discoveredPeripheral = discoveredPeripherals[indexPath.row]
        if let index = selectedDevice.firstIndex(where: { $0.peripheral == discoveredPeripheral.peripheral }) {
            selectedDevice.remove(at: index)
        } else {
            if discoveredPeripheral.rssi <= -90 {
                SVProgressHUD.showInfo(withStatus: LANGLOC("Bluetooth signal is too weak"))
                return
            }
            if selectedDevice.count > 5 {
                SVProgressHUD.showInfo(withStatus: "最多只能选择5个")
                return
            }
            selectedDevice.append(discoveredPeripheral)
        }
        self.tableView.reloadData()
    }
}

extension KLMAddDeviceTestViewController: KLMMeshManagerDelegate {
    
    func meshManager(_ manager: KLMMeshManager, didScanedDevice device: DiscoveredPeripheral){
        
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
    
    func meshManager(_ manager: KLMMeshManager, didActiveDevice device: Node) {
        KLMLog("配网成功")
        if KLMMesh.save() {
            
            if let index = discoveredPeripherals.firstIndex(where: {$0.device.uuid == device.uuid}) {
                totalDevcie += 1
                if let cell: KLMDeviceAddTestCell = self.tableView.cellForRow(at: IndexPath.init(row: index, section: 0)) as? KLMDeviceAddTestCell {
                    cell.setStatus = 1
                }
                print("成功的设备 = \(index)")
            }
        }
    }
    
    func meshManager(_ manager: KLMMeshManager, didFailToActiveDevice error: MessageError?, failDevice device: DiscoveredPeripheral) {
        KLMLog("配网失败了")
        if let index = discoveredPeripherals.firstIndex(where: {$0.device.uuid == device.device.uuid}) {
            totalDevcie += 1
            if let cell: KLMDeviceAddTestCell = self.tableView.cellForRow(at: IndexPath.init(row: index, section: 0)) as? KLMDeviceAddTestCell {
                cell.setStatus = 2
            }
            print("失败的设备 = \(index)")
        }
    }
}
