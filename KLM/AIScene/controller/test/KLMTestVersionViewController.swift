//
//  KLMTestVersionViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/24.
//

import UIKit

class KLMTestVersionViewController: UIViewController {

    @IBOutlet weak var liaohaoLab: UILabel!
    @IBOutlet weak var versionLab: UILabel!
    var BLEVersion: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "料号和固件版本"
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        SVProgressHUD.show()
        //读取数据
        let parame = parameModel(dp: .hardwareInfo)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
        
        versionLab.text = BLEVersion
    }
}

extension KLMTestVersionViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
//        if let value = message?.value as? [UInt8], value.count >= 5 , message?.dp == .hardwareInfo {
//
//            let data: String = "\(value[0]).\(value[1]).\(value[2]).\(value[3])\(value[4])"
//            liaohaoLab.text = data
//        }
        
        if let value = message?.value as? [UInt8], value.count >= 2 , message?.dp == .hardwareInfo {
            
            let gonglv = Int(value[0])
            let qudong = Int(value[1])
            if gonglv == 1 { //35W
                if qudong == 1 { //diodes
                    liaohaoLab.text = "1.10.19.0063"
                } else { //ocx
                    liaohaoLab.text = "1.10.19.0060"
                }
            } else if gonglv == 2 { //25W
                if qudong == 1 { //diodes
                    liaohaoLab.text = "1.10.19.0064"
                } else { //ocx
                    liaohaoLab.text = "1.10.19.0066"
                }
            } else if gonglv == 3 { //35W ble
                liaohaoLab.text = "1.10.19.0067"
            } else if gonglv == 4 { //25W ble
                liaohaoLab.text = "1.10.19.0068"
            } else {
                liaohaoLab.text = "0.0.0.0"
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
