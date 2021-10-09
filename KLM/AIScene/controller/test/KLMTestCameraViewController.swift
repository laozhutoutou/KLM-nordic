//
//  KLMTestCameraViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/9.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision

class KLMTestCameraViewController: UIViewController {

    @IBOutlet weak var cameraImageView: UIImageView!
    
    var isFineDevice = false
    
    private var centralManager: CBCentralManager!
    var currentIndex = 0
    /// 总的包数
    let totalNum = 100
    var cameraData: Data = Data()
    
    var myview: OpenGLView20!
    var yuvData: NSData!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        SVProgressHUD.dismiss()
//
//        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
//
//            self.centralManager.stopScan()
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        self.myview.setVideoSize(160, height: 120)
        self.myview.displayYUV420pData(self.yuvData as Data?, width: 160, height: 120)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        yuvData = NSData.init(bytes: list, length: list.count)
        self.myview = OpenGLView20.init(frame: CGRect.init(x: 20, y: 20, width: KLMScreenW - 40, height: 300))
        self.view.addSubview(self.myview)
        
        //搜索1828已配网设备
        //当前连接的节点是否是当前选中的节点
//        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
//
//            centralManager = CBCentralManager()
//            MeshNetworkManager.bearer.delegate = self
//            SVProgressHUD.show()
//            SVProgressHUD.setDefaultMaskType(.black)
//            startScanning()
//            DispatchQueue.main.asyncAfter(deadline: 25) {
//                //未能找到设备
//                if !self.isFineDevice {
//                    SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))
//                }
//            }
//        }
    }
    
    func startScanning() {
        
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
    }
    
    @IBAction func downLoad(_ sender: Any) {
        
        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
            
            SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))
            return
        }
        
        let parameTime = parameModel(dp: .cameraPic)
        KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMTestCameraViewController: CBCentralManagerDelegate {
    
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

extension KLMTestCameraViewController: BearerDelegate {
    
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

extension KLMTestCameraViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
        
    }
}

