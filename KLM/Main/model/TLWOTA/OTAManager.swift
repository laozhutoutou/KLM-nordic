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
    
    private var otaIndex: Int = -1
    private var offset: Int = 0
    private var writeOTAInterval: Double = 0.007
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
            KLMLog("OTAing, can't call repeated.")
            return false
        }
        guard let data = data, data.count > 0 else {
            KLMLog("OTA data is invalid.")
            return false
        }
        guard let node = node else {
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
        isStartScannig = false
        
        ///扫描不上提示超时
        DispatchQueue.main.async {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.scanTimeout), object: nil)
            self.perform(#selector(self.scanTimeout), with: nil, afterDelay: 12)
        }
        
        ///如果是直连设备，不会再广播，这个时候需要先断开直连设备
        if let bearer = MeshNetworkManager.bearer.proxies.first {
            if bearer.nodeUUID == currentNode.nodeuuidString {
                KLMLog("断开直连设备的连接")
                MeshNetworkManager.bearer.close()
//                DispatchQueue.main.asyncAfter(deadline: 2) {
//                    self.connectDevice()
//                }
//                return
            }
        }
        
        connectDevice()
    }
    
    private func connectDevice() {
        
        startMeshConnectBeforeGATTOTA()
        
    }
    
    private func startMeshConnectBeforeGATTOTA() {
        
        if centralManager.state == .poweredOn, isStartScannig == false {
            KLMLog("Start scan OTA device")
            isStartScannig = true
            centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
        }
    }
    
    ///连接设备超时
    @objc func meshConnectTimeoutBeforeGATTOTA() {
        KLMLog("OTA fail: startMeshConnect Timeout Before GATT OTA.")
        let error = BaseError.init()
        error.message = LANGLOC("Connecting TImeout")
        otaFailAction(error)
    }
    ///扫描超时
    @objc func scanTimeout() {
        
        KLMLog("Scanning Time out")
        let error = BaseError.init()
        error.message = LANGLOC("Scanning Time out")
        otaFailAction(error)
    }
    
    private func otaFailAction(_ error: BaseError?) {
        KLMLog("OTA fail")
        OTAing = false
        sendFinish = false
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
}

extension OTAManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        KLMLog("central state \(central.state)")
        switch central.state {
        case .poweredOn:
            if OTAing , isStartScannig == false {
                isStartScannig = true
                centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)

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

extension OTAManager: BearerDelegate {
    
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
}

extension OTAManager {
    
    @objc private func startSendGATTOTAPackets() {
        
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
        
        let writeLength = (lastLength >= 16) ? 16 : lastLength
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
