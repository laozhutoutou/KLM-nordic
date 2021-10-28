//
//  KLMBLEDFUViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/24.
//

import UIKit
import iOSDFULibrary
import CoreBluetooth

class KLMBLEDFUViewController: UIViewController {
    
    private var serviceInitiator = DFUServiceInitiator()
    private var centralManager: CBCentralManager!
    var isFineDevice = false
    var peripheral: CBPeripheral!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        SVProgressHUD.dismiss()
        
        self.centralManager.stopScan()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        DispatchQueue.main.asyncAfter(deadline: 25) {
            //未能找到设备
            if !self.isFineDevice {
                SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))

            }
        }
    }
    
    func startScanning() {
        
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    @IBAction func DFU(_ sender: Any) {
        
        if isFineDevice {
            SVProgressHUD.showProgress(0)
            serviceInitiator.start(target: self.peripheral)
            
        } else {
            
            SVProgressHUD.showError(withStatus: "设备未连接")
        }
    }
}

extension KLMBLEDFUViewController: CBCentralManagerDelegate {
    
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
                SVProgressHUD.showSuccess(withStatus: LANGLOC("connectSuccess"))
                KLMLog("找到已配网设备")
                self.peripheral = peripheral
                
                central.stopScan()
                
            }
        }
    }
}

extension KLMBLEDFUViewController: DFUServiceDelegate {
    func dfuStateDidChange(to state: DFUState) {
    
        switch state {
        case .connecting:
            
            KLMLog("connecting")
            
        case .completed:
            KLMLog("completed")
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

extension KLMBLEDFUViewController: DFUProgressDelegate {
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        
        SVProgressHUD.showProgress(Float(progress) / 100.0, status: "\(Int(progress))" + "%")
        KLMLog("Updating. Part \(part) of \(totalParts): \(progress)%")
    }
    
}

