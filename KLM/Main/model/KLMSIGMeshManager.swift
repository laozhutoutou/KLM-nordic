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
    
    func sigMeshManagerDidConnetctUnprovisionDevice(_ manager: KLMSIGMeshManager)
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
    
    func sigMeshManagerDidConnetctUnprovisionDevice(_ manager: KLMSIGMeshManager) {
        
        
    }
}

class KLMSIGMeshManager: NSObject {
    
    private var centralManager: CBCentralManager!
    weak var delegate:  KLMSIGMeshManagerDelegate?
    
    var discoveredPeripheral: DiscoveredPeripheral!
    private var provisioningManager: ProvisioningManager!
    var gattBearer: PBGattBearer?
    var provisonManager :KLMProvisionManager!
    
    var currentNode: Node!
    
    
    ///超时时间 - 配网超时时间
    var messageTimeout: Int = 20
    ///当前秒
    var currentTime: Int = 0
    ///定时器
    var messageTimer: Timer?
    
    //单例
    static let sharedInstacnce = KLMSIGMeshManager()
    private override init(){}
}

extension KLMSIGMeshManager {
    
    ///开始扫描
    func startScan(scanType: KLMSIGScanType) {
        
        centralManager = CBCentralManager()
        
        if scanType ==  .ScanForUnprovision{
            
            startScanning()
        }
    }
    ///开始连接
    func startConnect(discoveredPeripheral: DiscoveredPeripheral) {
        ///启动定时器
        messageTimeout = 8
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
    ///停止连接
    func stopConnectDevice() {
        
        self.gattBearer?.close()
        
    }
    
    ///开始配网
    func startActive() {
        
        ///启动定时器
        messageTimeout = 20
        startTime()
        
        let provisonManager = KLMProvisionManager.init(discoveredPeripheral: self.discoveredPeripheral, bearer: self.gattBearer!)
        provisonManager.delegate = self
        provisonManager.identify()
        self.provisonManager = provisonManager
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
            
            //超时不再接收消息
            MeshNetworkManager.instance.delegate = nil
            self.gattBearer?.delegate = nil
            self.gattBearer?.close()
            
            var err = MessageError()
            err.message = "Add light timeout"
            self.delegate?.sigMeshManager(self, didFailToActiveDevice: err)
            
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
            
            let discoveredPeripheral: DiscoveredPeripheral = (unprovisionedDevice, peripheral, RSSI.intValue)
            //过滤一下设备
            if unprovisionedDevice.uuid.uuidString.count >= 2 {
                //以DD开头的设备是我们的
                let id = unprovisionedDevice.uuid.uuidString.substring(to: 2)
                if id == "DD" {
                    KLMLog("rssi = \(discoveredPeripheral.rssi)")
//                    if apptype == .test && discoveredPeripheral.rssi < -45{
//                        return
//                    }
                    self.delegate?.sigMeshManager(self, didScanedDevice: discoveredPeripheral)
                }
            }
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
        
        //停止定时
        stopTime()
        
        var err = MessageError()
        err.message = error?.localizedDescription
        self.delegate?.sigMeshManager(self, didFailToActiveDevice: err)
    }
    
    func provisionManagerNodeAddSuccess(_ manager: KLMProvisionManager) {
        
        SVProgressHUD.show(withStatus: "composition")
        
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
        
        ///连接成功停止计时
        stopTime()
        
        KLMLog("connect Unprovision success")
        
        self.delegate?.sigMeshManagerDidConnetctUnprovisionDevice(self)
        
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        
    }
}

extension KLMSIGMeshManager: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        ///过滤消息，不是当前手机发出的消息不处理（这个可以不加，因为不是当前手机的信息nordic底层已经处理）
        if manager.meshNetwork?.localProvisioner?.node?.unicastAddress != destination {
            KLMLog("别的手机发的消息")
            return
        }
        
        switch message {
        case let status as ConfigAppKeyStatus://node add app key success
            if status.status == .success{
                
                KLMLog("node appkey success")
                SVProgressHUD.show(withStatus: "Add app key to model")
                
                //给自定义vendor model 配置APP key
                let model = KLMHomeManager.getModelFromNode(node: self.currentNode)!
                guard model.boundApplicationKeys.isEmpty else {
                    return
                }
                
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
        case is ConfigCompositionDataStatus:
            
            KLMLog("composition success")
            SVProgressHUD.show(withStatus: "Add app key to node")
            
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
            return
            
        case let status as ConfigModelAppStatus:
            if status.status == .success {
                
                //停止计时
                stopTime()
                
                //整个流程配置完成
                KLMLog("OTA model appkey success")
                
                self.delegate?.sigMeshManager(self, didActiveDevice: self.currentNode)
                return
            }
            
        default:
            break
        }
        
        //停止计时
        stopTime()
        
        var err = MessageError()
        err.message = "Add light failed"
        self.delegate?.sigMeshManager(self, didFailToActiveDevice: err)
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
