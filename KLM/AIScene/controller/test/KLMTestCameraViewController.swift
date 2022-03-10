//
//  KLMTestCameraViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/9.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision
import SVProgressHUD
import Kingfisher

class KLMTestCameraViewController: UIViewController {

//    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    //    var isFineDevice = false
//
//    private var centralManager: CBCentralManager!
//
//    /// 总字节数
//    let totalBytes: Int = 28800
//    /// 接收的数据
//    var cameraData: Data = Data()
//
//    var myview: OpenGLView20!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        KLMSmartNode.sharedInstacnce.delegate = self
          
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        SVProgressHUD.dismiss()

//        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
//
//            self.centralManager.stopScan()
//        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        self.myview = OpenGLView20.init(frame: cameraView.bounds)
//        cameraView.addSubview(self.myview)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
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
//        } else {
//            SVProgressHUD.show()
//            SVProgressHUD.setDefaultMaskType(.black)
//            DispatchQueue.main.asyncAfter(deadline: 1.5) {
//                SVProgressHUD.dismiss()
//            }
//        }
        
//        SVProgressHUD.show()
//        SVProgressHUD.setDefaultMaskType(.black)
//        DispatchQueue.main.asyncAfter(deadline: 1.5) {
//            SVProgressHUD.dismiss()
//        }
    }
    
//    func startScanning() {
//
//        centralManager.delegate = self
//        centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid], options: nil)
//    }
    
    @IBAction func downLoad(_ sender: Any) {
        
//        if KLMHomeManager.currentConnectNode?.uuid != KLMHomeManager.currentNode.uuid {
//
//            SVProgressHUD.showError(withStatus: LANGLOC("searchDeviceTip"))
//            return
//        }
//        KLMLog("开始下载")
//        resetData()
//
//        SVProgressHUD.showProgress(0)
//        SVProgressHUD.setDefaultMaskType(.black)
        
//        SVProgressHUD.show()
        let parameTime = parameModel(dp: .cameraPic)
        KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
    }
    
    ///清空数据
//    func resetData() {
//
////        cameraData.removeAll()
//    }
}

//extension KLMTestCameraViewController: CBCentralManagerDelegate {
//
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//
////        if central.state != .poweredOn {
////            KLMLog("Central is not powered on")
////        } else {
////            startScanning()
////        }
//    }
    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
//                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
//
//        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data{
//
//            let subData = data.suffix(from: 2).hex
//
//            //搜索到当前节点广播
//            if KLMHomeManager.currentNode.UUIDString == subData {
//                isFineDevice = true
//                KLMLog("找到已配网设备")
//                //记录连接节点UUID
//                MeshNetworkManager.bearer.connectNode = subData
//                //断开之前设备连接
//                MeshNetworkManager.bearer.close()
//
//                let bearer = GattBearer(target: peripheral)
//
//                //bearerdidopen 才能OK
//                MeshNetworkManager.bearer.isOpen = false
//                //才能切换
//                MeshNetworkManager.bearer.isConnectionModeAutomatic = false
//                //连接新设备
//                MeshNetworkManager.bearer.use(proxy: bearer)
//                //开始连接
//                bearer.open()
//                central.stopScan()
//
//            }
//        }
//    }
//}

//extension KLMTestCameraViewController: BearerDelegate {
//
//    func bearerDidOpen(_ bearer: Bearer) {
//
//        SVProgressHUD.showSuccess(withStatus: LANGLOC("connectSuccess"))
//        //打开自动连接
//        MeshNetworkManager.bearer.isConnectionModeAutomatic = true
//        MeshNetworkManager.bearer.open()
//        KLMLog("connectSuccess")
//
//    }
//
//    func bearer(_ bearer: Bearer, didClose error: Error?) {
//
//
//    }
//}

extension KLMTestCameraViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
//        SVProgressHUD.dismiss()
        if message?.dp == .cameraPic{
            
            if let data = message?.value as? [UInt8], data.count >= 4 {
                
                let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp"
                KLMLog("ip = \(ip)")
                ipTextField.text = ip
                let url = URL.init(string: ip)
                
                /// forceRefresh 不需要缓存
                imageView.kf.indicatorType = .activity
                imageView.kf.setImage(with: url, placeholder: nil, options: [.forceRefresh])
            }
//
//                //接收数据
//                cameraData.append(data)
//                KLMLog("length = \(cameraData.count)")
//
//                let progress: Float = Float(cameraData.count) / Float(totalBytes)
//                SVProgressHUD.showProgress(progress, status: "\(Int(progress * 100))" + "%")
//
//                if cameraData.count >= totalBytes {
//                    ///接收完成,显示图像
//                    KLMLog("图像传输完成")
//                    self.myview.setVideoSize(160, height: 120)
//                    self.myview.displayYUV420pData(self.cameraData, width: 160, height: 120)
//                    SVProgressHUD.showSuccess(withStatus: "下载完成")
//                    return
//                }
//
//                let parameTime = parameModel(dp: .cameraPic)
//                KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
//
//            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
        
    }
}

