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

class KLMDFUTestViewController: UIViewController {

    @IBOutlet weak var linkUrlField: UITextField!
    @IBOutlet weak var SSIDField: UITextField!
    @IBOutlet weak var passField: UITextField!
    
    @IBOutlet weak var upGradeBtn: UIButton!
    
    private var otaStart: Bool = false
    private var mClearFlash: Bool = false
    private var mUrlEnable: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        linkUrlField.text = "https://note.youdao.com/yws/api/personal/file/WEB2af9301225228e275d1718e461e7e2a3?method=download&shareKey=9edf59662e9897c9ed91d91788c905ca"
        SSIDField.text = "SJKJ"
        passField.text = "26671627"
        
        MeshNetworkManager.instance.delegate = self
        
        Observable.combineLatest(linkUrlField.rx.text.orEmpty, SSIDField.rx.text.orEmpty, passField.rx.text.orEmpty) { mailText, passwordText, codeText  in
            
            if mailText.isEmpty ||  passwordText.isEmpty || codeText.isEmpty{
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
        
        otaStart = true
        KLMLog("Send OTA bin Version")
        
        let binId: Int =  1
        let version: Int = 2
        let bytes: [UInt8] = [UInt8(binId & 0xff),
                              UInt8(binId >> 8 & 0xff),
                              UInt8(version & 0xff),
                              UInt8((version >> 8 & 0xff)),
                              getFlag(),
                              UInt8(0xf000 & 0xff),
                              UInt8((0xf000 >> 8) & 0xff)
        ]
        let parameters = Data.init(bytes: bytes, count: bytes.count)
        let model: Model = KLMHomeManager.getOTAModelFromNode(node: KLMHomeManager.currentNode)!
        if let opCode = UInt8("0C", radix: 16) {
            
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
                
            } catch {
                print(error)
                
            }
        }
    }
    
    func getFlag() -> UInt8 {

        return (mClearFlash ? 1 : 0) |
        (mUrlEnable ? 0b10 : 0)
    }
    
    func espOtaStart() {
        
        KLMLog("Send OTA Message")
        
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
        
        
        let url: String = self.linkUrlField.text!
        let urlSSID: String = self.SSIDField.text!
        let urlPassword: String = self.passField.text!
        
        //256
        var urlBytes: [UInt8] = [UInt8](url.data(using: String.Encoding.ascii)!)
        urlBytes = urlBytes + [UInt8].init(repeating: 0, count: 256 - urlBytes.count)
        //32
        var urlSSIDBytes: [UInt8] = [UInt8](urlSSID.data(using: String.Encoding.ascii)!)
        urlSSIDBytes = urlSSIDBytes + [UInt8].init(repeating: 0, count: 32 - urlSSIDBytes.count)
        //64
        var urlPasswordBytes: [UInt8] = [UInt8](urlPassword.data(using: String.Encoding.ascii)!)
        urlPasswordBytes = urlPasswordBytes + [UInt8].init(repeating: 0, count: 64 - urlPasswordBytes.count)
        
        let bytes: [UInt8] = EspDataUtils.mergeBytes(bytes: [0x00], moreBytes:
                                                     ssid,
                                                     password,
                                                     urlBytes,
                                                     urlSSIDBytes,
                                                     urlPasswordBytes)
        let parameters = Data.init(bytes: bytes, count: bytes.count)
        let model: Model = KLMHomeManager.getOTAModelFromNode(node: KLMHomeManager.currentNode)!
        if let opCode = UInt8("0E", radix: 16) {
            
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
                
            } catch {
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
            ///接收到binVersion数据
            if otaStart == true {
                otaStart = false
                
                ///开始发送数据
                espOtaStart()
            }
            
        default:
            break
        }
        
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        KLMLog("消息发送成功")
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        
        otaStart = false
        KLMLog("消息发送失败 = \(error)")
    }
    
}
