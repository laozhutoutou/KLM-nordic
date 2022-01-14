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
    
    ///版本
    var BLEVersionData: KLMVersion.KLMVersionData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SSIDField.text = "SJKJ"
        passField.text = "26671627"
        
        upGradeBtn.layer.cornerRadius = upGradeBtn.height / 2
        
        MeshNetworkManager.instance.delegate = self
        MeshNetworkManager.bearer.delegate = self
        
        Observable.combineLatest(SSIDField.rx.text.orEmpty, passField.rx.text.orEmpty) {ssidText, passwordText  in
            
            if ssidText.isEmpty || passwordText.isEmpty{
                return false
            } else {
                return true
            }
        }.bind(to: upGradeBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        
    }

    @IBAction func upgrade(_ sender: Any) {
        
        sendBinVersion()
    }
    
    func sendBinVersion() {
        
        ///进度条
        SVProgressHUD.showProgress(0)
        SVProgressHUD.setDefaultMaskType(.black)
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
                
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                print(error)
                
            }
        }
    }
    
    func getFlag() -> UInt8 {

        return (mClearFlash ? 1 : 0) |
        (mUrlEnable ? 0b10 : 0)
    }
    
    func espOtaStart() {
        
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

//        //256
//        let url: String = KLMUrl("api/file/download/\(BLEVersionData.id)")
//        var urlBytes: [UInt8] = [UInt8](url.data(using: String.Encoding.ascii)!)
//        urlBytes = urlBytes + [UInt8].init(repeating: 0, count: 256 - urlBytes.count)
//        //32
//        var urlSSIDBytes: [UInt8] = [UInt8](urlSSID.data(using: String.Encoding.ascii)!)
//        urlSSIDBytes = urlSSIDBytes + [UInt8].init(repeating: 0, count: 32 - urlSSIDBytes.count)
//        //64
//        var urlPasswordBytes: [UInt8] = [UInt8](urlPassword.data(using: String.Encoding.ascii)!)
//        urlPasswordBytes = urlPasswordBytes + [UInt8].init(repeating: 0, count: 64 - urlPasswordBytes.count)
        
        
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
               
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                print(error)
                
            }
        }
    }
}

extension KLMDFUTestViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        switch message {
        case let message as UnknownMessage:
            KLMLog(message.debugDescription)
            /// 00CD00FF 00CF00FF
            ///接收到binVersion数据
            if String(format: "%08X", message.opCode) == "00CD00FF" {
                
                ///开始发送数据
                espOtaStart()
            }
            
            if String(format: "%08X", message.opCode) == "00CF00FF" {
                
                ///更新完成
                if message.parameters?.hex == "24723639" {
                    ///设备重启中
                    SVProgressHUD.showProgress(1.0, status: "Restarting")
                    DispatchQueue.main.asyncAfter(deadline: 8) {
                        
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("Updatecomplete"))
                        DispatchQueue.main.asyncAfter(deadline: 0.5) {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                    
                } else {
                    
                    //进度
                    if let parameters = message.parameters {
                        if parameters.count >= 2 {
                            //00 01 对应成功百分比为1，
                            let statu = parameters[0]
                            let PP = parameters[1]
                            switch statu {
                            case 0://进度
                                
                                let progress: Float = Float(PP) / 100.0
                                SVProgressHUD.showProgress(progress, status: "\(Int(progress * 100))" + "%")
                                
                            default:
                                SVProgressHUD.showError(withStatus: "Upgrade failure")
                                break
                            }
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
        
        KLMLog("消息发送失败 = \(error)")
        SVProgressHUD.showError(withStatus: "Upgrade failure")
    }
}

extension KLMDFUTestViewController: BearerDelegate {
    
    func bearerDidOpen(_ bearer: Bearer) {
        
        
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        
        SVProgressHUD.dismiss()
    }
}
