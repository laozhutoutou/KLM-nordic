//
//  KLMSIGMeshManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/16.
//

import Foundation
import nRFMeshProvision
import CoreBluetooth

enum KLMSIGScanType {
    case ScanForUnprovision
    case ScanForProxyed
}

protocol KLMSIGMeshManagerDelegate: AnyObject {
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didScanedDevice device: DiscoveredPeripheral)
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node)
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?)
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didSendMessage message: MeshMessage)
}

extension KLMSIGMeshManagerDelegate {
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didScanedDevice device: DiscoveredPeripheral){
        // This method is optional.
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?){
        // This method is optional.
        
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didSendMessage message: MeshMessage) {
        // This method is optional.
        
    }
}

class KLMSIGMeshManager: NSObject {
    
    private var centralManager: CBCentralManager!
    weak var delegate:  KLMSIGMeshManagerDelegate?
    
    var discoveredPeripheral: DiscoveredPeripheral!
    private var provisioningManager: ProvisioningManager!
    var gattBearer: PBGattBearer!
    var provisonManager :KLMProvisionManager!
    
    var currentNode: Node!
    
    ///超时时间 - 配网超时时间
    let messageTimeout: Int = 20
    ///当前秒
    var currentTime: Int = 0
    ///定时器
    var messageTimer: Timer?
    
    //单例
    static let sharedInstacnce = KLMSIGMeshManager()
    private override init(){}
}

extension KLMSIGMeshManager {
    
    func startScan(scanType: KLMSIGScanType) {
        
        centralManager = CBCentralManager()
        
        if scanType ==  .ScanForUnprovision{
            
            startScanning()
        }
    }
    ///开始配网
    func startActive(discoveredPeripheral: DiscoveredPeripheral) {
        ///启动定时器
        startTime()
        
        KLMLog("startActive")
        self.discoveredPeripheral = discoveredPeripheral
        
        let bb = PBGattBearer(target: discoveredPeripheral.peripheral)
        bb.logger = MeshNetworkManager.instance.logger
        bb.delegate = self
        bb.open()
        self.gattBearer = bb
        stopScanning()
    }
    
    func stopActiveDevice() {
        
        
    }
}

extension KLMSIGMeshManager {
    
    private func startScanning() {
        
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshProvisioningService.uuid],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }
    
    func stopScanning() {
        
        centralManager.stopScan()
    }
    
    //开始计时
    func startTime() {
        
        stopTime()
        
        messageTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(UpdateTimer), userInfo: nil, repeats: true)
    }
    
    //停止计时
    func stopTime() {
        currentTime = 0
        if messageTimer != nil {
            messageTimer?.invalidate()
            messageTimer = nil
        }
    }
    
    @objc func UpdateTimer() {
        
        currentTime += 1
        if currentTime > messageTimeout {//超时
            stopTime()
            
            SVProgressHUD.showError(withStatus: LANGLOC("Timeout"))
        }
    }
}

extension KLMSIGMeshManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state != .poweredOn {
            KLMLog("Central is not powered on")
        } else {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData){
            
            let discoveredPeripheral = (unprovisionedDevice, peripheral, RSSI.intValue)
            self.delegate?.sigMeshManager(self, didScanedDevice: discoveredPeripheral)
            
        }
    }
}
extension KLMSIGMeshManager: KLMProvisionManagerDelegate {
    
    func getCompositionData(node: Node) {
        
        self.currentNode = node
        
        MeshNetworkManager.instance.delegate = self
        let message = ConfigCompositionDataGet()
        do {
            try MeshNetworkManager.instance.send(message, to: node)
            
        } catch  {
            print(error)
        }
    }
    
    func provisionManager(_ manager: KLMProvisionManager, didFailChange error: Error?) {
        
        var err = MessageError()
        err.message = error?.localizedDescription
        self.delegate?.sigMeshManager(self, didFailToActiveDevice: err)
    }
    
    func provisionManagerNodeAddSuccess(_ manager: KLMProvisionManager) {
        
        //composition
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let node = network.node(for: self.discoveredPeripheral.device)!
            if !node.isCompositionDataReceived {
                KLMLog("start composition")
                self.getCompositionData(node: node)
            }
        }
    }
    
}

extension KLMSIGMeshManager: BearerDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        
        KLMLog("connect Unprovision success")
        let bb = bearer as? ProvisioningBearer
        
        let provisonManager = KLMProvisionManager.init(discoveredPeripheral: self.discoveredPeripheral, bearer: bb!)
        provisonManager.delegate = self
        provisonManager.identify()
        self.provisonManager = provisonManager
        
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        
        SVProgressHUD.dismiss()
        var err = MessageError()
        err.message = error?.localizedDescription
        self.delegate?.sigMeshManager(self, didFailToActiveDevice: err)
        
    }
}

extension KLMSIGMeshManager: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        switch message {
        case let status as ConfigAppKeyStatus://node add app key success
            if status.status == .success{
                
                KLMLog("node appkey success")
                
                //给自定义vendor model 配置APP key
                let model = KLMHomeManager.getModelFromNode(node: self.currentNode)!
                guard !model.boundApplicationKeys.isEmpty else {
                    
                    let keys = self.currentNode.applicationKeysAvailableFor(model)
                    let applicationKey = keys.first
                    let message = ConfigModelAppBind(applicationKey: applicationKey!, to: model)!
                    
                    do {
                        try MeshNetworkManager.instance.send(message, to: self.currentNode)
                    } catch  {
                        print(error)
                    }
                    return
                }
            }
        case is ConfigCompositionDataStatus:
            
            KLMLog("composition success")
            
            //给node 配置app key
            if !self.currentNode.applicationKeys.isEmpty {
                
                return
            }
            
            let applicationKey = MeshNetworkManager.instance.meshNetwork!.applicationKeys.first
            let message = ConfigAppKeyAdd(applicationKey: applicationKey!)
            do {
                try MeshNetworkManager.instance.send(message, to: self.currentNode)
                
            } catch  {
                print(error)
            }
        case let status as ConfigModelAppStatus:
            if status.status == .success {
                
                if status.modelIdentifier == 1 { //vendorModel appkey配置成功
                    
                    KLMLog("vendorModel appkey success")
                    
                    ///给OTA model配置APPKey
                    let OTAModel = KLMHomeManager.getOTAModelFromNode(node: self.currentNode)!
                    guard !OTAModel.boundApplicationKeys.isEmpty else {
                        
                        let keys = self.currentNode.applicationKeysAvailableFor(OTAModel)
                        let applicationKey = keys.first
                        let message = ConfigModelAppBind(applicationKey: applicationKey!, to: OTAModel)!
                        
                        do {
                            try MeshNetworkManager.instance.send(message, to: self.currentNode)
                        } catch  {
                            print(error)
                        }
                        return
                    }
                    return
                }
                
                //停止计时
                stopTime()
                
                //整个流程配置完成
                KLMLog("OTA model appkey success")
                
                self.delegate?.sigMeshManager(self, didActiveDevice: self.currentNode)
                
            }
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address,
                            error: Error){
        //失败停止定时器
        stopTime()
        SVProgressHUD.dismiss()
        var err = MessageError()
        err.message = error.localizedDescription
        self.delegate?.sigMeshManager(self, didFailToActiveDevice: err)
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address) {
        
        self.delegate?.sigMeshManager(self, didSendMessage: message)
    }
    
}


