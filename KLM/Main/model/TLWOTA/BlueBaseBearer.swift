import Foundation
import CoreBluetooth
import nRFMeshProvision

///OTA 特征
let kOTA_CharacteristicsID: String = "00010203-0405-0607-0809-0A0B0C0D2B12"

class BlueBaseBearer: NSObject, Bearer {
    
    var dataDelegate: BearerDataDelegate?
    var supportedPduTypes: PduTypes = .networkPdu
    var isOpen: Bool = false
    func send(_ data: Data, ofType type: PduType) throws {
        
    }
    
    private let centralManager: CBCentralManager
    private var basePeripheral: CBPeripheral!
    ///OTA 特征
    private var OTACharacteristic:  CBCharacteristic?
    /// The UUID associated with the peer.
    public let identifier: UUID

    public weak var delegate: BearerDelegate?
    var sendPacketFinishBlock: SendPacketsFinishCallback?
    
    private var isOpened: Bool = false
    
    public convenience init(target peripheral: CBPeripheral) {
        self.init(targetWithIdentifier: peripheral.identifier)
    }
    public init(targetWithIdentifier uuid: UUID) {
        centralManager  = CBCentralManager()
        identifier = uuid
        super.init()
        centralManager.delegate = self
    }
    
    open func open() {
        if centralManager.state == .poweredOn && basePeripheral?.state == .disconnected {
            KLMLog("Connecting to \(basePeripheral.name ?? "Unknown Device")...")
            centralManager.connect(basePeripheral, options: nil)
        }
        isOpened = true
    }
    
    open func close() {
        if basePeripheral?.state == .connected || basePeripheral?.state == .connecting {
            KLMLog("Cancelling connection...")
            centralManager.cancelPeripheralConnection(basePeripheral)
        }
        isOpened = false
    }
}

extension BlueBaseBearer: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        KLMLog("Central Manager state changed to \(central.state)")
        if central.state == .poweredOn {
            guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [identifier]).first else {
                KLMLog("Device with identifier \(identifier.uuidString) not found")
                isOpened = false
                return
            }
            basePeripheral = peripheral
            basePeripheral.delegate = self
            if isOpened {
                open()
            }
        } else {
            
            delegate?.bearer(self, didClose: nil)
        }
    }
    
    open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == basePeripheral {
            KLMLog("Connected to \(peripheral.name ?? "Unknown Device")")
            basePeripheral.discoverServices(nil)
        }
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if let services = peripheral.services {
            for service in services {
                KLMLog("services Found")
                basePeripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                let uuid = CBUUID.init(string: kOTA_CharacteristicsID)
                if uuid == characteristic.uuid {
                    KLMLog("OTA characteristic found")
                    OTACharacteristic = characteristic
                    if characteristic.properties.contains(.notify) {
                        KLMLog("Enabling notifications...")
                        basePeripheral.setNotifyValue(true, for: characteristic)
                    }
                }  
            }
        }
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == OTACharacteristic, characteristic.isNotifying else {
            return
        }
        
        KLMLog("Data Out notifications enabled")
        KLMLog("GATT Bearer open and ready")
        delegate?.bearerDidOpen(self)
    }
    
    open func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == OTACharacteristic, let data = characteristic.value else {
            return
        }
        KLMLog("<- 设备回复 = \(data.hex)")
        dataDelegate?.bearer(self, didDeliverData: data, ofType: .networkPdu)
    }
    
    open func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        KLMLog("disconnect \(error?.localizedDescription)")
        if delegate != nil {
            delegate?.bearer(self, didClose: error)
        }
    }
}

extension BlueBaseBearer {
    
    func sendOTAData(data: Data?, complete: SendPacketsFinishCallback?) {
        sendPacketFinishBlock = complete
        guard let data = data, data.count != 0 else {
            KLMLog("current packets is empty.")
            if let complete = complete {
                complete()
            }
            return
        }
        
        guard let characteristic = OTACharacteristic else {
            KLMLog("current characteristic is empty.")
            if let complete = complete {
                complete()
            }
            return
        }
        
        basePeripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        
        if let complete = complete {
            complete()
        }
    }
}
