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
    
    var deviceName = ""
    
    var isHaveDevice: Bool = false {
        
        didSet {
            
            if isHaveDevice {//搜索到设备
                
                self.contentView.isHidden = false
                searchView.isHidden = true
                
            } else { //未搜索到设备
                
                self.contentView.isHidden = true
                searchView.isHidden = false
            }
        }
    }
    
    deinit {
        
        KLMSIGMeshManager.sharedInstacnce.stopScanning()
    }
    
    private var discoveredPeripherals: [DiscoveredPeripheral] = []
    private var selectedDevice: UnprovisionedDevice?
    private var alert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("addDevice")
        self.contentView.isHidden = true

        //展示搜索页面
        searchView = KLMDeviceSearchView.deviceSearchView(frame: CGRect(x: 0, y: 200, width: KLMScreenW, height: 300))
        self.view.addSubview(searchView)
        
        KLMSIGMeshManager.sharedInstacnce.delegate = self
        
        contentView.backgroundColor = appBackGroupColor
        view.backgroundColor = appBackGroupColor
        
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        searchDevice()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       
    }
    
    func searchDevice() {
        
        discoveredPeripherals.removeAll()
        self.tableView.reloadData()
        
        isHaveDevice = false
        
        KLMSIGMeshManager.sharedInstacnce.startScan(scanType: .ScanForUnprovision)
        
        DispatchQueue.main.asyncAfter(deadline: 30){
            
            if self.isHaveDevice {

                KLMSIGMeshManager.sharedInstacnce.stopScanning()

            }

        }

    }
    
    //连接设备
    func connectDevice(model: DiscoveredPeripheral) {
        
        ///弹框
        let vc = CMDeviceNamePopViewController()
        vc.nametype = .nameTypeNewDevice
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.nameBlock = { [weak self] name in
            
            guard let self = self else { return }
            self.deviceName = name
            
            SVProgressHUD.show(withStatus: "connecting...")
            SVProgressHUD.setDefaultMaskType(.black)
            
            
            
            KLMSIGMeshManager.sharedInstacnce.startActive(discoveredPeripheral: model)
            
        }
        present(vc, animated: true, completion: nil)
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
            
        } else {
            
            discoveredPeripherals.append(device)
            tableView.insertRows(at: [IndexPath(row: discoveredPeripherals.count - 1, section: 0)], with: .fade)
        }
        
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node) {
        
        //连接成功
        SVProgressHUD.showSuccess(withStatus: LANGLOC("connectSuccess"))
        
        //停止
        KLMSIGMeshManager.sharedInstacnce.stopScanning()
        
        //记录当前设备
        KLMHomeManager.sharedInstacnce.smartNode = device
        
        device.name = self.deviceName
        
        if MeshNetworkManager.instance.save() {
            
            //刷新首页
            NotificationCenter.default.post(name: .deviceAddSuccess, object: nil)
            
            //跳转页面
            DispatchQueue.main.asyncAfter(deadline: 0.5){
                
//                self.navigationController?.popViewController(animated: true)

                let vc = KLMDeviceEditViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: Error?) {
        
        KLMShowError(error)
        
    }
}

