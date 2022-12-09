//
//  OTAManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/9/21.
//

import Foundation
import nRFMeshProvision
import CoreBluetooth

typealias CallBackSuccess = () -> ()
typealias CallBackFailure = (_ error: BaseError?) -> ()
typealias CallBackProgress = (_ progress: Float) -> ()
typealias SendPacketsFinishCallback = () -> ()

class OTAManager: NSObject {
    
    private var centralManager: CBCentralManager
    private var currentPeripheral: CBPeripheral?
    private var OTAing: Bool = false
    private var currentNode: Node!
    private var data: NSData!
    private var blueBearer: BlueBaseBearer?
    
    var callBackSuccess: CallBackSuccess?
    var callBackFailure: CallBackFailure?
    var callBackProgress: CallBackProgress?
    var sendPacketFinishBlock: SendPacketsFinishCallback?
    
    ///第几包，从0开始发
    private var otaIndex: Int = -1
    private var offset: Int = 0
    private var writeOTAInterval: Double = 0.007
    private var perLength: Int = 16
    /// 最大丢包次数，超过这个次数，提示失败
    private var maxLostPackageTime = 10
    private var lostPackageTime = 0
    private var sendFinish = false
    private var isStartScannig = false
    
    //单例
    static let shared = OTAManager()
    private override init(){
        centralManager = CBCentralManager()
        super.init()
        centralManager.delegate = self
    }
    
    func startOTAWithOtaData(data: NSData?, node: Node?, successAction:@escaping CallBackSuccess, failAction: @escaping CallBackFailure, progressAction: @escaping CallBackProgress) -> Bool {
        if OTAing {
            SVProgressHUD.showInfo(withStatus: "OTAing, can't call repeated.")
            KLMLog("OTAing, can't call repeated.")
            return false
        }
        guard let data = data, data.count > 0 else {
            SVProgressHUD.showInfo(withStatus: "OTA data is invalid.")
            KLMLog("OTA data is invalid.")
            return false
        }
        guard let node = node else {
            SVProgressHUD.showInfo(withStatus: "node is invaid.")
            KLMLog("node is invaid")
            return false
        }
        
        self.data = data
        currentNode = node
        callBackSuccess = successAction
        callBackFailure = failAction
        callBackProgress = progressAction
        
        otaNext()
        return true
    }
    
    private func otaNext() {
        
        OTAing = true
        otaIndex = -1
        offset = 0
        lostPackageTime = 0
        isStartScannig = false
        
        ///扫描不上提示超时
        DispatchQueue.main.async {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.scanTimeout), object: nil)
            self.perform(#selector(self.scanTimeout), with: nil, afterDelay: 12)
        }
        
        ///如果是直连设备，不会再广播，这个时候需要先断开直连设备
//        if let bearer = MeshNetworkManager.bearer.proxies.first {
//            if bearer.nodeUUID == currentNode.nodeuuidString {
//                KLMLog("断开直连设备的连接")
//                MeshNetworkManager.bearer.close()
//            }
//        }
        
        MeshNetworkManager.bearer.close()
        
        connectDevice()
    }
    
    private func connectDevice() {
        
        startMeshConnectBeforeGATTOTA()
        
    }
    
    private func startMeshConnectBeforeGATTOTA() {
        
        if centralManager.state == .poweredOn, isStartScannig == false {
            KLMLog("Start scan OTA device")
            isStartScannig = true
            centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    ///连接设备超时
    @objc func meshConnectTimeoutBeforeGATTOTA() {
        KLMLog("OTA fail: startMeshConnect Timeout Before GATT OTA.")
        let error = BaseError.init()
        error.message = LANGLOC("Connecting Timeout")
        otaFailAction(error)
    }
    ///扫描超时
    @objc func scanTimeout() {
        
        KLMLog("Scanning Time out")
        let error = BaseError.init()
        error.message = LANGLOC("Time out. Maybe the light is connected by others, please let others disconnect or turn off Bluetooth, and try again.")
        otaFailAction(error)
    }
    
    private func otaFailAction(_ error: BaseError?) {
        KLMLog("OTA fail")
        OTAing = false
        sendFinish = false
        lostPackageTime = 0
        centralManager.stopScan()
        ///关闭连接
        blueBearer?.close()
        ///打开后台自动连接
        MeshNetworkManager.bearer.open()
        DispatchQueue.main.async {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            ///
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.startSendGATTOTAPackets), object: nil)
        }
        ///给时间 MeshNetworkManager.bearer.open()
        DispatchQueue.main.asyncAfter(deadline: 2) {
            if let callBackFailure = self.callBackFailure {
                callBackFailure(error)
            }
        }
    }
    
    private func otaSuccessAction() {
        KLMLog("OTA success")
        OTAing = false
        sendFinish = false
        lostPackageTime = 0
        blueBearer?.close()
        centralManager.stopScan()
        ///打开后台自动连接
        MeshNetworkManager.bearer.open()
        ///连接上才认为是成功,给多点时间连接
        DispatchQueue.main.asyncAfter(deadline: 5) {
            if let callBackSuccess = self.callBackSuccess {
                callBackSuccess()
            }
        }
    }
    
    ///主动关闭
    func close() {
        ///打开后台自动连接
        MeshNetworkManager.bearer.open()
        KLMLog("Close OTA")
        OTAing = false
        sendFinish = false
        blueBearer?.close()
        centralManager.stopScan()
        DispatchQueue.main.async {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.startSendGATTOTAPackets), object: nil)
        }
    }
    
    ///丢包继续传
    private func continueUpgrade(index: Int) {
        
        OTAing = true
        
        ///比如index是10，对于APP来说是第9包，调用 startSendGATTOTAPackets otaIndex会加1
        otaIndex = index - 2
        offset = otaIndex * perLength + perLength
        
        ///开始发送数据
        startSendGATTOTAPackets()
    }
}

extension OTAManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        KLMLog("central state \(central.state)")
        switch central.state {
        case .poweredOn:
            if OTAing , isStartScannig == false {
                isStartScannig = true
                centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])

            }
        case .poweredOff:
            break
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Is it a Network ID beacon?
        if let networkId = advertisementData.networkId {
            
            guard MeshNetworkManager.instance.meshNetwork!.matches(networkId: networkId) else {
                // A Node from another mesh network.
                return
            }
        } else {
            // Is it a Node Identity beacon?
            guard let nodeIdentity = advertisementData.nodeIdentity,
                  MeshNetworkManager.instance.meshNetwork!.matches(hash: nodeIdentity.hash, random: nodeIdentity.random) else {
                // A Node from another mesh network.
                return
            }
        }
        
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data{
            if data.count >= 8 {
                let subData: Data = data[2...7]
                let uuid = subData.hex
                KLMLog("nodeUUID = \(uuid)")
                if uuid == currentNode.nodeuuidString { ///扫描到了设备
                    //信号太差不给升级
                    if RSSI.intValue < -80 {
                        SVProgressHUD.show(withStatus: LANGLOC("Bluetooth signal is too weak"))
                        return
                    }
                    centralManager.stopScan()
                    currentPeripheral = peripheral
                    ///连接设备
                    let bb = BlueBaseBearer(target: peripheral)
                    bb.delegate = self
                    bb.dataDelegate = self
                    blueBearer = bb
                    bb.open()
                    
                    ///取消扫描超时
                    DispatchQueue.main.async {
                        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.scanTimeout), object: nil)
                    }
                    
                    ///开始连接定时
                    DispatchQueue.main.async {
                        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.meshConnectTimeoutBeforeGATTOTA), object: nil)
                        self.perform(#selector(self.meshConnectTimeoutBeforeGATTOTA), with: nil, afterDelay: 10)
                    }
                }
            }
        }
    }
}

extension OTAManager: BearerDelegate, BearerDataDelegate {

    func bearerDidOpen(_ bearer: Bearer) {
        ///设备连接上取消超时
        DispatchQueue.main.async {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.meshConnectTimeoutBeforeGATTOTA), object: nil)
        }
        ///开始发送数据
        startSendGATTOTAPackets()
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        if let bee = bearer as? BlueBaseBearer, let periferal = currentPeripheral {
            ///断开连接的是当前
            if bee.identifier == periferal.identifier {
                if sendFinish {
                    otaSuccessAction()
                } else {
                    let err = BaseError.init()
                    err.message = error?.localizedDescription
                    otaFailAction(err)
                }
            }
        }
    }
    ///设备回复数据
    func bearer(_ bearer: nRFMeshProvision.Bearer, didDeliverData data: Data, ofType type: nRFMeshProvision.PduType) {
        
        if data.count == 3, data[0] != 0 { ///设备回复错误
            
            if data[0] == 1 { //丢包
                
                lostPackageTime += 1
                
                //停止发送
                OTAing = false
                DispatchQueue.main.async {
                    NSObject.cancelPreviousPerformRequests(withTarget: self)
                    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.startSendGATTOTAPackets), object: nil)
                }

                ///有可能回复错误的时候，APP端不断发送，sendFinish为true
                sendFinish = false
                
                if lostPackageTime >= maxLostPackageTime {
                    
                    KLMLog("超过最大丢包数量")
                    let err = BaseError.init()
                    err.message = LANGLOC("The maximum number of package lost is exceeded.")
                    otaFailAction(err)
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: 0.5) {
                    
                    var index: UInt16 = 0
                    (data[1...2] as NSData).getBytes(&index, length:2)
                    KLMLog("丢失的包数 = \(index)")
                    self.continueUpgrade(index: Int(index))
                }
                                
            } else {
                
                let err = BaseError.init()
                err.message = LANGLOC("Device error,Please upgrade again") + "error code - \(data[0])"
                otaFailAction(err)
            }
        }
    }
}

extension OTAManager {
    
    @objc private func startSendGATTOTAPackets() {
        
        if OTAing == false {
            return
        }
        
        let lastLength = data.count - offset
        //OTA 结束包特殊处理
        if lastLength == 0 {
            let byte: [UInt8] = [0x02,0xff]
            let endData = NSData.init(bytes: byte, length: 2)
            sendOTAEndData(data: endData, index: otaIndex, complete: nil)
            sendFinish = true
            return
        }
        otaIndex += 1
        //OTA开始包特殊处理
        if otaIndex == 0 {
            sendReadFirmwareVersion(complete: nil)
            sendStartOTA(complete: nil)
        }
                
        let writeLength = (lastLength >= perLength) ? perLength : lastLength
        let writeData = data.subdata(with: NSMakeRange(offset, writeLength))
        offset += writeLength
        let progress: Float = Float(offset) * 100 / Float(data.length)
        if let callBackProgress = callBackProgress {
            callBackProgress(progress)
        }
        
        sendOTAData(data: writeData as NSData, index: otaIndex) {[weak self] in
            guard let self = self else {return }
            //注意：index=0与index=1之间的时间间隔修改为300ms，让固件有充足的时间进行ota配置。
            if self.otaIndex == 0 {
                DispatchQueue.main.async {
                    self.perform(#selector(self.startSendGATTOTAPackets), with: nil, afterDelay: 0.3)
                }
            } else {
                DispatchQueue.main.async {
                    self.perform(#selector(self.startSendGATTOTAPackets), with: nil, afterDelay: self.writeOTAInterval)
                }
            }
        }
    }
    
    private func sendOTAData(data: NSData, index: Int, complete: SendPacketsFinishCallback?) {
        
        let writeData = LibTools.getOTAData(data as Data, index: Int32(index))
        blueBearer?.sendOTAData(data: writeData, complete: complete)
    }
    
    private func sendReadFirmwareVersion(complete: SendPacketsFinishCallback?) {
        
        let writeData = LibTools.getReadFirmwareVersion()
        blueBearer?.sendOTAData(data: writeData, complete: complete)
    }
    
    private func sendStartOTA(complete: SendPacketsFinishCallback?) {
        
        let writeData = LibTools.getStartOTA()
        blueBearer?.sendOTAData(data: writeData, complete: complete)
    }
    
    private func sendOTAEndData(data: NSData, index: Int, complete: SendPacketsFinishCallback?) {
        
        let writeData = LibTools.getOTAEnd(data as Data, index: Int32(index))
        blueBearer?.sendOTAData(data: writeData, complete: complete)
    }
}
