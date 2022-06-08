//
//  KLMDFUTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/1/5.
//

import UIKit
import nRFMeshProvision
import RxSwift
import RxCocoa
import SVProgressHUD
import SystemConfiguration.CaptiveNetwork

class KLMDFUTestViewController: UIViewController {
    
    @IBOutlet weak var SSIDField: UITextField!
    @IBOutlet weak var passField: UITextField!
    
    @IBOutlet weak var upGradeBtn: UIButton!
    
    private var mClearFlash: Bool = false
    private var mUrlEnable: Bool = true
    
    private var isTureWiFi = true
    
    //定时器
    private lazy var timer: KLMTimer = {
        let timer = KLMTimer()
        timer.delegate = self
        return timer
    }()
    
    ///版本
    var BLEVersionData: KLMVersion.KLMVersionData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///填充WIFI信息
        if let result = KLMHomeManager.getWIFIMsg() {
            
            SSIDField.text = result.SSID
            passField.text = result.password
        } else {
            ///获取手机连接的WiFi
            
        }
        
        upGradeBtn.layer.cornerRadius = upGradeBtn.height / 2
        
        Observable.combineLatest(SSIDField.rx.text.orEmpty, passField.rx.text.orEmpty) {ssidText, passwordText  in
            
            if ssidText.isEmpty || passwordText.isEmpty{
                return false
            } else {
                return true
            }
        }.bind(to: upGradeBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        //弹出更新提示框
        KLMAlertController.showAlertWithTitle(title: LANGLOC("Warning"), message: LANGLOC("Please do not move the mobile phone. and keep the Bluetooth connection between the mobile phone and the light during the update process."))

        
    }
    
    @IBAction func upgrade(_ sender: Any) {
        
        //连接节点成功
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        KLMConnectManager.shared.connectToNode(node: KLMHomeManager.currentNode) { [weak self] in
            guard let self = self else { return }
            
            self.sendBinVersion()
            
        } failure: {
            
        }
    }
    
    func sendBinVersion() {
        
        SVProgressHUD.show(withStatus: LANGLOC("Verify version"))
        MeshNetworkManager.instance.delegate = self
        
        //开始计时
        timer.startTimer(timeOut: 40)
        
        ///进度条
        KLMLog("Send OTA bin Version")
        
        let binId: Int =  1
        let version: Int = EspDataUtils.binVersionString2Int(version: BLEVersionData.fileVersion)
        KLMLog("version = \(version)")
        let bytes: [UInt8] = [UInt8(binId & 0xff),
                              UInt8(binId >> 8 & 0xff),
                              UInt8(version & 0xff),
                              UInt8((version >> 8 & 0xff)),
                              getFlag(),
                              UInt8(0xf000 & 0xff),
                              UInt8((0xf000 >> 8) & 0xff)
        ]
        let parameters = Data.init(bytes: bytes, count: bytes.count)
        let model: Model = KLMHomeManager.getModelFromNode(node: KLMHomeManager.currentNode)!
        if let opCode = UInt8("0C", radix: 16) {
            
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
                
            } catch {
                
                SVProgressHUD.showInfo(withStatus: error.localizedDescription)
                print(error)
                
            }
        }
    }
    
    func getFlag() -> UInt8 {
        
        return (mClearFlash ? 1 : 0) |
        (mUrlEnable ? 0b10 : 0)
    }
    
    func espOtaStart() {
        
        //开始计时
        timer.startTimer(timeOut: 40)
        
        KLMLog("Send OTA Start")
        
        let aa: Character = "a"
        let zz: Character = "z"
        
        let ssid: [UInt8] = [
            aa.asciiValue! + UInt8(arc4random_uniform(UInt32(zz.asciiValue! - aa.asciiValue!))),
            aa.asciiValue! + UInt8(arc4random_uniform(UInt32(zz.asciiValue! - aa.asciiValue!)))
        ]
        let password: [UInt8] = [
            aa.asciiValue! + UInt8(arc4random_uniform(UInt32(zz.asciiValue! - aa.asciiValue!))),
            aa.asciiValue! + UInt8(arc4random_uniform(UInt32(zz.asciiValue! - aa.asciiValue!)))
        ]
        
        let urlSSID: String = self.SSIDField.text!
        let urlPassword: String = self.passField.text!
        
        //64
        let url: String = KLMUrl("api/file/download/\(BLEVersionData.id)")
        var urlBytes: [UInt8] = [UInt8](url.data(using: String.Encoding.ascii)!)
        urlBytes = urlBytes + [UInt8].init(repeating: 0, count: 64 - urlBytes.count)
        //32
        var urlSSIDBytes: [UInt8] = [UInt8](urlSSID.data(using: String.Encoding.ascii)!)
        urlSSIDBytes = urlSSIDBytes + [UInt8].init(repeating: 0, count: 32 - urlSSIDBytes.count)
        //32
        var urlPasswordBytes: [UInt8] = [UInt8](urlPassword.data(using: String.Encoding.ascii)!)
        urlPasswordBytes = urlPasswordBytes + [UInt8].init(repeating: 0, count: 32 - urlPasswordBytes.count)
        //token  256 - 32
        let token: String = KLMGetUserDefault("token") as! String
        var tokenBytes: [UInt8] = [UInt8](token.data(using: String.Encoding.ascii)!)
        tokenBytes = tokenBytes + [UInt8].init(repeating: 0, count: 256 - 32 - tokenBytes.count)
        
        let bytes: [UInt8] = EspDataUtils.mergeBytes(bytes: [0x00], moreBytes:
                                                        ssid,
                                                     password,
                                                     urlBytes,
                                                     urlSSIDBytes,
                                                     urlPasswordBytes,
                                                     tokenBytes
                                                     
        )
        let parameters = Data.init(bytes: bytes, count: bytes.count)
        let model: Model = KLMHomeManager.getModelFromNode(node: KLMHomeManager.currentNode)!
        if let opCode = UInt8("0E", radix: 16) {
            
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
                
            } catch {
                
                SVProgressHUD.showInfo(withStatus: error.localizedDescription)
                print(error)
                
            }
        }
    }
}

extension KLMDFUTestViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        ///过滤消息，不是当前手机发出的消息不处理（这个可以不加，因为不是当前手机的信息nordic底层已经处理）
        if manager.meshNetwork?.localProvisioner?.node?.unicastAddress != destination {
            KLMLog("别的手机发的消息")
            return
        }
        
        ///不是当前节点的消息不处理
        if source != KLMHomeManager.currentNode.unicastAddress {
            KLMLog("别的节点回的消息")
            return
        }
        
        switch message {
        case let message as UnknownMessage:
            KLMLog(message.debugDescription)
            /// 00CD00FF 00CF00FF
            ///接收到binVersion数据
            if String(format: "%08X", message.opCode) == "00CD00FF" {
                
                timer.stopTimer()
                //设备在更新中
                if message.parameters?.hex == "0000" {
                    
                    KLMLog("设备正在更新中...")
                    SVProgressHUD.showInfo(withStatus: LANGLOC("The device is upgrading"))
                    
                } else if message.parameters?.hex == "0001" {
                    
                    KLMLog("已经是最新版本，不需要升级")
                    SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
                    
                } else {//正常
                    
                    SVProgressHUD.show(withStatus: LANGLOC("Version is OK"))
                    
                    ///开始发送数据
                    espOtaStart()
                }
            }
            ///开始接收到更新数据
            if String(format: "%08X", message.opCode) == "00CF00FF" {
                
                timer.stopTimer()
                
                ///更新完成
                if message.parameters?.hex == "24723639" {
                    
                    ///设备重启中
                    SVProgressHUD.show(withStatus: LANGLOC("Restarting"))
                    DispatchQueue.main.asyncAfter(deadline: 6) {
                        
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("Updatecomplete"))
                        DispatchQueue.main.asyncAfter(deadline: 0.5) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                    return
                }
                
                //进度
                if let parameters = message.parameters {
                    if parameters.count >= 2 {
                        //00 01 对应成功百分比为1，
                        let statu = parameters[0]
                        /// 0-100
                        let PP = parameters[1]
                        switch statu {
                        case 0://进度
                            
                            timer.startTimer(timeOut: 40)
                            
                            if PP == 0 { ///准备更新
                                
                                SVProgressHUD.show(withStatus: LANGLOC("Preparing to update"))
                                return
                            }
                            
                            if isTureWiFi {
                                isTureWiFi = false
                                ///存储wifi信息
                                KLMHomeManager.cacheWIFIMsg(SSID: self.SSIDField.text!, password: self.passField.text!)
                            }
                            
                            let progress: Float = Float(PP) / 100.0 * 0.7
                            SVProgressHUD.showProgress(progress, status: "\(Int(progress * 100))" + "%")
                        case 0xFC:
                            timer.startTimer(timeOut: 100)
                            KLMLog("正在搜索其他待升级设备")
                            SVProgressHUD.show(withStatus: LANGLOC("Searching for other devices to be upgraded"))
                        case 0xFF: ///其他设备在升级
//                            timer.startTimer(timeOut: 60)
                            KLMLog("Please wait while other devices are upgrading")
                            SVProgressHUD.show(withStatus: LANGLOC("Please wait while other devices are upgrading"))
                        case 0xFE: ///
                            KLMLog("其他设备连接不上")
                        case 0xFD: ///
                            KLMLog("其他设备升级超时")
                        case 0xFB:
                            timer.startTimer(timeOut: 40)
                            KLMLog("初始化WiFi")
                            SVProgressHUD.show(withStatus: LANGLOC("WiFi initialization"))
                        case 0xFA:
                            timer.startTimer(timeOut: 60)
                            KLMLog("通过WiFi连接网络")
                            SVProgressHUD.show(withStatus: LANGLOC("Connect to the internet via Wi-Fi"))
                        case 1:
                            SVProgressHUD.dismiss()
                            KLMLog("wifi 名称或者密码错误")
                            ///提示框
                            KLMAlertController.showAlertWithTitle(title: nil, message: LANGLOC("Please check WiFi name or password"))
                            
                        case 2:
                            SVProgressHUD.dismiss()
                            KLMLog("升级中断，灯断开网络连接")
                            ///提示框
                            KLMAlertController.showAlertWithTitle(title: nil, message: LANGLOC("Upgrade interrupted, please keep networks open"))
                            
                        default:
                            KLMLog("Upgrade failure")
                            break
                        }
                    }
                }
            }
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        KLMLog("消息发送成功")
        
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        
        KLMLog("升级发送消息失败 - \(error.localizedDescription)")

    }
}

extension KLMDFUTestViewController: KLMTimerDelegate {
    
    func timeDidTimeout(_ timer: KLMTimer) {
        
        KLMLog("蓝牙连接超时，消息未收到")
        SVProgressHUD.dismiss()
        KLMAlertController.showAlertWithTitle(title: nil, message: LANGLOC("Connection timed out."))
    }
}

