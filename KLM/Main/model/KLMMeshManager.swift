//
//  KLMMeshManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/5/17.
//

import Foundation
import nRFMeshProvision
import CoreBluetooth

protocol KLMMeshManagerDelegate: AnyObject {
    
    func meshManager(_ manager: KLMMeshManager, didScanedDevice device: DiscoveredPeripheral)
    
    func meshManager(_ manager: KLMMeshManager, didActiveDevice device: Node)
    
    func meshManager(_ manager: KLMMeshManager, didFailToActiveDevice error: MessageError?, failDevice device: DiscoveredPeripheral)
    
}

extension KLMMeshManagerDelegate {
    
    func meshManager(_ manager: KLMMeshManager, didScanedDevice device: DiscoveredPeripheral){
        // This method is optional.
    }
    
    func meshManager(_ manager: KLMMeshManager, didActiveDevice device: Node) {
        // This method is optional.
        
    }
    
    func meshManager(_ manager: KLMMeshManager, didFailToActiveDevice error: MessageError?, failDevice device: DiscoveredPeripheral) {
        // This method is optional.
        
    }
    
}


class KLMMeshManager: NSObject {
    
    private var centralManager: CBCentralManager!
    weak var delegate:  KLMMeshManagerDelegate?
    
    var discoveredPeripherals: [DiscoveredPeripheral]!
    var currentIndex: Int = 0
    var gattBearer: PBGattBearer?
    var provisonManager :KLMProvisionManager!
    var nodes: [Node] = [Node]()
    var timers: [KLMTimer] = [KLMTimer]()
    
    //单例
    static let shared = KLMMeshManager()
    private override init(){}
    
    ///开始扫描
    func startScan() {
        
        centralManager = CBCentralManager()
        startScanning()
    }
    
    func startActive(device: [DiscoveredPeripheral]) {
        
        timers.forEach{$0.stopTimer()}
        timers.removeAll()
        nodes.removeAll()
        currentIndex = 0
        discoveredPeripherals = device
        startConnect()
        stopScanning()
    }
}

extension KLMMeshManager {
    
    private func startScanning() {
        
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshProvisioningService.uuid],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }
    
    func stopScanning() {
        
        centralManager.stopScan()
    }
    
    private func startConnect() {
        
        ///开始定时
        let timer = KLMTimer.init()
        timer.tag = currentIndex
        timer.startTimer(timeOut: 30)
        timer.delegate = self
        timers.append(timer)
        
        let device: DiscoveredPeripheral = discoveredPeripherals[currentIndex]
        let bb = PBGattBearer(target: device.peripheral)
        bb.logger = MeshNetworkManager.instance.logger
        bb.delegate = self
        bb.open()
        self.gattBearer = bb
        
    }
}

extension KLMMeshManager: KLMTimerDelegate {
    
    func timeDidTimeout(_ timer: KLMTimer) {
        
        KLMLog("时间超时 - 第\(timer.tag + 1)个设备")
        var err = MessageError()
        err.message = "Add light timeout"
        self.delegate?.meshManager(self, didFailToActiveDevice: err, failDevice: discoveredPeripherals[timer.tag])
    }
}
extension KLMMeshManager: CBCentralManagerDelegate {
    
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
                    if apptype == .test && discoveredPeripheral.rssi < -52{
                        return
                    }
                    self.delegate?.meshManager(self, didScanedDevice: discoveredPeripheral)
                }
            }
        }
    }
}

extension KLMMeshManager: BearerDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        
        KLMLog("connect Unprovision success")
        
        //开始配网
        let device: DiscoveredPeripheral = discoveredPeripherals[currentIndex]
        let provisonManager = KLMProvisionManager.init(discoveredPeripheral: device, bearer: self.gattBearer!)
        provisonManager.delegate = self
        provisonManager.identify()
        self.provisonManager = provisonManager
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        
    }
    
}

extension KLMMeshManager: KLMProvisionManagerDelegate {
    
    func provisionManager(_ manager: KLMProvisionManager, didFailChange error: Error?) {
        
        ///停止计时
        timers.first(where: {$0.tag == currentIndex})?.stopTimer()
        
        var err = MessageError()
        err.message = error?.localizedDescription
        self.delegate?.meshManager(self, didFailToActiveDevice: err, failDevice: manager.discoveredPeripheral)
        
        if currentIndex >= discoveredPeripherals.count - 1 {
            return
        }
        
        currentIndex += 1
        //开始连接其他设备
        startConnect()
    }
    
    func provisionManagerNodeAddSuccess(_ manager: KLMProvisionManager) {
        
        SVProgressHUD.show(withStatus: "composition")
        //节点添加完成的开始composition，同时开始其他节点添加
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let device: DiscoveredPeripheral = manager.discoveredPeripheral
            let node = network.node(for: device.device)!
            nodes.append(node)
            
            if !node.isCompositionDataReceived {
                KLMLog("start composition")
                self.getCompositionData(node: node)
            }
        }
        
        if currentIndex >= discoveredPeripherals.count - 1 {
            return
        }
        
        currentIndex += 1
        //开始连接其他设备
        startConnect()
    }
    
    func getCompositionData(node: Node) {
                
        MeshNetworkManager.instance.delegate = self
        let message = ConfigCompositionDataGet()
        do {
            try MeshNetworkManager.instance.send(message, to: node)
            
        } catch  {
            print(error)
        }
    }
}

extension KLMMeshManager: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        ///过滤消息，不是当前手机发出的消息不处理（这个可以不加，因为不是当前手机的信息nordic底层已经处理）
        if manager.meshNetwork?.localProvisioner?.node?.unicastAddress != destination {
            KLMLog("别的手机发的消息")
            return
        }
        
        //假如时间超时，再收到消息不再处理
//        if let node = nodes.first(where: {$0.unicastAddress == source}) {
//            if let index = discoveredPeripherals.firstIndex(where: {$0.device.uuid == node.uuid}) {
//                //超时后定时无效
//                if timers.first(where: {$0.tag == index})?.timeIsValid() == false {
//
//                    return
//                }
//            }
//        }
        
        switch message {
        case let status as ConfigAppKeyStatus://node add app key success
            if status.status == .success{
                
                KLMLog("node appkey success")
                
                SVProgressHUD.show(withStatus: "Add app key to model")
                
                //给自定义vendor model 配置APP key
                if let node = nodes.first(where: {$0.unicastAddress == source}) {
                    
                    let model = KLMHomeManager.getModelFromNode(node: node)!
                    guard model.boundApplicationKeys.isEmpty else {
                        return
                    }
                    
                    let keys = node.applicationKeysAvailableFor(model)
                    let applicationKey = keys.first
                    let message = ConfigModelAppBind(applicationKey: applicationKey!, to: model)!
                    
                    do {
                        try MeshNetworkManager.instance.send(message, to: node)
                    } catch  {
                        print(error)
                    }
                }
                
                return
            }
        case is ConfigCompositionDataStatus:
            
            KLMLog("composition success")
            SVProgressHUD.show(withStatus: "Add app key to node")
            
            if let node = nodes.first(where: {$0.unicastAddress == source}) {
                
                //给node 配置app key
                if !node.applicationKeys.isEmpty {
                    
                    return
                }
                
                let applicationKey = MeshNetworkManager.instance.meshNetwork!.applicationKeys.first
                let message = ConfigAppKeyAdd(applicationKey: applicationKey!)
                do {
                    try MeshNetworkManager.instance.send(message, to: node)
                    
                } catch  {
                    print(error)
                }
            }
            
            return
            
        case let status as ConfigModelAppStatus:
            if status.status == .success {
                
                //整个流程配置完成
                KLMLog("OTA model appkey success")
                SVProgressHUD.show(withStatus: "Configuration finish")
                if let node = nodes.first(where: {$0.unicastAddress == source}) {
                    //停止计时
                    if let index = discoveredPeripherals.firstIndex(where: {$0.device.uuid == node.uuid}) {
                        
                        timers.first(where: {$0.tag == index})?.stopTimer()
                    }
                    
                    self.delegate?.meshManager(self, didActiveDevice: node)
                }
                
                return
            }
            
        default:
            break
        }
        
        //停止计时
        if let node = nodes.first(where: {$0.unicastAddress == source}) {
            if let index = discoveredPeripherals.firstIndex(where: {$0.device.uuid == node.uuid}) {
                
                timers.first(where: {$0.tag == index})?.stopTimer()
                
                var err = MessageError()
                err.message = "Add light failed"
                self.delegate?.meshManager(self, didFailToActiveDevice: err, failDevice: discoveredPeripherals[index])
            }
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address,
                            error: Error){
        //失败停止定时器
        if let node = nodes.first(where: {$0.unicastAddress == localElement.unicastAddress}) {
            if let index = discoveredPeripherals.firstIndex(where: {$0.device.uuid == node.uuid}) {
                
                timers.first(where: {$0.tag == index})?.stopTimer()
                
                SVProgressHUD.dismiss()
                var err = MessageError()
                err.message = error.localizedDescription
                self.delegate?.meshManager(self, didFailToActiveDevice: err, failDevice: discoveredPeripherals[index])
            }
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address) {
        

    }
    
}
