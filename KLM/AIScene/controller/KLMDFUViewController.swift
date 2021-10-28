//
//  KLMDFUViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/17.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision
import SVProgressHUD
import iOSDFULibrary

enum updateType {
    case BLEUpdate
    case MCUUpdate
    case Both
}

class KLMDFUViewController: UIViewController {
    
    var dataPackageArray: [String]!
    var currentIndex = 0
    var isFineDevice = false
    
    ///蓝牙更新
    private var serviceInitiator = DFUServiceInitiator()
    var peripheral: CBPeripheral!
    
    var MCUVersion: Int!
    var BLEVersion: Int!
    var updateTy: updateType = .Both
    
    private var centralManager: CBCentralManager?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if updateTy != .BLEUpdate {
            
            KLMSmartNode.sharedInstacnce.delegate = self
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        SVProgressHUD.dismiss()
        
        self.centralManager?.stopScan()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("Softwareupdate")
        
        if BLEVersion >= BLENewestVersion {
            updateTy = .MCUUpdate
        }
        
        if MCUVersion >= MCUNewestVersion {
            updateTy = .BLEUpdate
            
        }
        
        if updateTy == .BLEUpdate {
            
            setupBLE()
            
        } else if updateTy == .MCUUpdate {
            
            setupMCU()
        } else {
            
            setupBoth()
        }
        
    }
    
    func setupBLE() {
        
        let path = Bundle.main.path(forResource: "BLEDFU", ofType: "zip")
        let url = URL.init(fileURLWithPath: path!)
        let firmware = DFUFirmware(urlToZipFile: url)
        
        serviceInitiator.delegate = self
        serviceInitiator.progressDelegate = self
        serviceInitiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        serviceInitiator = serviceInitiator.with(firmware: firmware!)
        
        centralManager = CBCentralManager()
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        
        startScanning()
        
        DispatchQueue.main.asyncAfter(deadline: 10) {
            //未能找到设备
            if !self.isFineDevice {
                SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))

            }
        }
    }
    
    func setupMCU() {
        
        //搜索1828已配网设备
        //当前连接的节点是否是当前选中的节点
        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
            
            centralManager = CBCentralManager()
            MeshNetworkManager.bearer.delegate = self
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            
            startScanning()
            
            DispatchQueue.main.asyncAfter(deadline: 10) {
                //未能找到设备
                if !self.isFineDevice {
                    SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))

                }
            }
        }
    }
    
    func setupBoth() {
        
        ///蓝牙
        let path = Bundle.main.path(forResource: "BLEDFU", ofType: "zip")
        let url = URL.init(fileURLWithPath: path!)
        let firmware = DFUFirmware(urlToZipFile: url)
        serviceInitiator.delegate = self
        serviceInitiator.progressDelegate = self
        serviceInitiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = true
        serviceInitiator = serviceInitiator.with(firmware: firmware!)
        centralManager = CBCentralManager()
        
        ///MCU
        MeshNetworkManager.bearer.delegate = self
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        
        startScanning()
        
        DispatchQueue.main.asyncAfter(deadline: 10) {
            //未能找到设备
            if !self.isFineDevice {
                SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))

            }
        }
    }
    
    func startScanning() {
        
        centralManager?.delegate = self
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
    }
    
    @IBAction func DFU(_ sender: Any) {
        
        if updateTy == .BLEUpdate {
            
            if isFineDevice {
                SVProgressHUD.showProgress(0)
                SVProgressHUD.setDefaultMaskType(.black)
                updateBLE()
                
            } else {
                
                SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))
            }
            
        } else {
            
            if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
                
                SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))
                return
            }
            
            ///both的话先更新MCU，再更新蓝牙
            SVProgressHUD.showProgress(0)
            SVProgressHUD.setDefaultMaskType(.black)
            updateMCU()
            
        }
    }
    
    func updateBLE() {
        KLMLog("开始更新蓝牙")
        serviceInitiator.start(target: self.peripheral)
    }
    
    func updateMCU() {
        
        ///更新MCU
        dataPackageArray = KLMUpdateManager.sharedInstacnce.dealFirmware()
        currentIndex = 0
        let first = KLMUpdateManager.sharedInstacnce.getUpdateFirstPackage()
        let parame = parameModel(dp: .checkVersion, value: first)
        KLMLog("开始更新MCU")
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMDFUViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state != .poweredOn {
            KLMLog("Central is not powered on")
        } else {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        ///BLE
        if updateTy == .BLEUpdate {
            
            if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data{
                
                let subData = data.suffix(from: 2).hex
                
                //搜索到当前节点广播
                if KLMHomeManager.currentNode.UUIDString == subData {
                    isFineDevice = true
                    SVProgressHUD.showSuccess(withStatus: LANGLOC("connectSuccess"))
                    KLMLog("找到已配网设备")
                    self.peripheral = peripheral
                    
                    central.stopScan()
                    
                }
            }
        } else if updateTy == .MCUUpdate {
            
            if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data{
                
                let subData = data.suffix(from: 2).hex
                
                //搜索到当前节点广播
                if KLMHomeManager.currentNode.UUIDString == subData {
                    isFineDevice = true
                    KLMLog("找到已配网设备")
                    //记录连接节点UUID
                    MeshNetworkManager.bearer.connectNode = subData
                    //断开之前设备连接
                    MeshNetworkManager.bearer.close()
                    
                    let bearer = GattBearer(target: peripheral)
                    
                    //bearerdidopen 才能OK
                    MeshNetworkManager.bearer.isOpen = false
                    //才能切换
                    MeshNetworkManager.bearer.isConnectionModeAutomatic = false
                    //连接新设备
                    MeshNetworkManager.bearer.use(proxy: bearer)
                    //开始连接
                    bearer.open()
                    central.stopScan()
                    
                }
            }
        } else {
            
            if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data{
                
                let subData = data.suffix(from: 2).hex
                
                //搜索到当前节点广播
                if KLMHomeManager.currentNode.UUIDString == subData {
                    isFineDevice = true
                    KLMLog("找到已配网设备")
                    
                    ///蓝牙
                    self.peripheral = peripheral
                    
                    ///MCU
                    if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
                        
                        ///切换Bearer
                        //记录连接节点UUID
                        MeshNetworkManager.bearer.connectNode = subData
                        //断开之前设备连接
                        MeshNetworkManager.bearer.close()
                        
                        let bearer = GattBearer(target: peripheral)
                        
                        //bearerdidopen 才能OK
                        MeshNetworkManager.bearer.isOpen = false
                        //才能切换
                        MeshNetworkManager.bearer.isConnectionModeAutomatic = false
                        //连接新设备
                        MeshNetworkManager.bearer.use(proxy: bearer)
                        //开始连接
                        bearer.open()
                        
                    } else {
                        
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("connectSuccess"))
                    }
                    
                    central.stopScan()
                    
                }
            }
        }
    }
}

extension KLMDFUViewController: BearerDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        
        SVProgressHUD.showSuccess(withStatus: LANGLOC("connectSuccess"))
        //打开自动连接
        MeshNetworkManager.bearer.isConnectionModeAutomatic = true
        MeshNetworkManager.bearer.open()
        KLMLog("connectSuccess")
        
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        
    }
}

extension KLMDFUViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? String, value == "FF"{
            
            //最后一包
            if currentIndex >= dataPackageArray.count {
                KLMLog("更新包发送完成")
                //发送完成
                let parame = parameModel(dp: .checkVersion, value: "01")
                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
                
                return
            }
            
            if updateTy == .MCUUpdate {
                
                let progress: Float = Float(currentIndex) / Float(dataPackageArray.count)
                SVProgressHUD.showProgress(progress, status: "\(Int(progress * 100))" + "%")
            } else {///both，mcu占70，ble占30
                
                let pp: Float = 70.0 * Float(currentIndex) / Float(dataPackageArray.count)
                SVProgressHUD.showProgress(pp / 100.0, status: "\(Int(pp))" + "%")
            }
            
            let package = dataPackageArray[currentIndex]
            let parame = parameModel(dp: .DFU, value: package)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            KLMLog("------------------\(currentIndex)")
            currentIndex += 1
            
        } else {
            
            // 01 完成更新
            if let value = message?.value as? String, value == "01" {
                
                KLMLog("MCU更新完成")
                if updateTy == .MCUUpdate {
                    
                    DispatchQueue.main.asyncAfter(deadline: 4) {
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("Updatecomplete"))
                        DispatchQueue.main.asyncAfter(deadline: 1) {
                            
                            self.navigationController?.popViewController(animated: true)
                        }
                       
                    }
                } else {///更新蓝牙
                    
                    self.updateBLE()
                }
                
                return
            }
            
            //错误 00
            SVProgressHUD.showError(withStatus: "error")
            KLMLog("Update error")
            DispatchQueue.main.asyncAfter(deadline: 1) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
        
    }
}

extension KLMDFUViewController: DFUServiceDelegate {
    func dfuStateDidChange(to state: DFUState) {
    
        switch state {
        case .connecting:
            
            KLMLog("connecting")
            
        case .completed:
            KLMLog("蓝牙更新完成")
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            DispatchQueue.main.asyncAfter(deadline: 1) {
                self.navigationController?.popToRootViewController(animated: true)
            }
        case .uploading:
            KLMLog("uploading")
        default:
            break
        }
        
    }
    
    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        KLMLog("error = \(message)")
        SVProgressHUD.showError(withStatus: message)
    }
    
}

extension KLMDFUViewController: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        
        ///both，mcu占70，ble占30
        if updateTy == .BLEUpdate {
            SVProgressHUD.showProgress(Float(progress) / 100.0, status: "\(Int(progress))" + "%")
        } else {///both
            ///
            
            let pp: Float = 3.0 * Float(progress) / 10.0 + 70.0
            SVProgressHUD.showProgress(pp / 100.0, status: "\(Int(pp))" + "%")
        }
        
        KLMLog("Updating. Part \(part) of \(totalParts): \(progress)%")
    }
    
}

