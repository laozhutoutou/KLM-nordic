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

class KLMDFUViewController: UIViewController {
    
    
    
    var dataPackageArray: [String]!
    var currentIndex = 0
    var isFineDevice = false
    
    private var centralManager: CBCentralManager!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        SVProgressHUD.dismiss()
        
        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
            
            self.centralManager.stopScan()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //搜索1828已配网设备
        //当前连接的节点是否是当前选中的节点
        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
            
            centralManager = CBCentralManager()
            MeshNetworkManager.bearer.delegate = self
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            startScanning()
            DispatchQueue.main.asyncAfter(deadline: 25) {
                //未能找到设备
                if !self.isFineDevice {
                    SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))
//                    self.centralManager.stopScan()
                }
            }
        }
    }
    
    func startScanning() {
        
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
    }

    @IBAction func DFU(_ sender: Any) {
        
        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
            
            SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))
            return
        }
        
        dataPackageArray = KLMUpdateManager.sharedInstacnce.dealFirmware()
        
        SVProgressHUD.showProgress(0)
        SVProgressHUD.setDefaultMaskType(.black)
        
        let first = KLMUpdateManager.sharedInstacnce.getUpdateFirstPackage()
        let parame = parameModel(dp: .checkVersion, value: first)
        KLMLog("开始更新")
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
            
            let progress: Float = Float(currentIndex) / Float(dataPackageArray.count)
            SVProgressHUD.showProgress(progress, status: "\(Int(progress * 100))" + "%")
            
            let package = dataPackageArray[currentIndex]
            let parame = parameModel(dp: .DFU, value: package)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            KLMLog("------------------\(currentIndex)")
            currentIndex += 1
            
        } else {
            
            // 01 完成更新
            if let value = message?.value as? String, value == "01" {
                
                KLMLog("更新完成")
                DispatchQueue.main.asyncAfter(deadline: 4) {
                    SVProgressHUD.showSuccess(withStatus: "Update complete")
                    DispatchQueue.main.asyncAfter(deadline: 1) {
                        
                        self.navigationController?.popViewController(animated: true)
                    }
                   
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
