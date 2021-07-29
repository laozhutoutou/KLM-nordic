//
//  KLMTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/21.
//

import UIKit

class KLMTestViewController: UIViewController {
    
    var WW: Int = 0
    var CW: Int = 0
    var R: Int = 0
    var G: Int = 0
    var B: Int = 0
    var A: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        KLMSmartNode.sharedInstacnce.delegate = self
    }

    @IBAction func value(_ sender: UISlider) {
        
        
        switch sender.tag {
        case 0:
            WW = Int(sender.value)
        case 1:
            CW = Int(sender.value)
        case 2:
            R = Int(sender.value)
        case 3:
            G = Int(sender.value)
        case 4:
            B = Int(sender.value)
        case 5:
            A = Int(sender.value)
        default:
            break
        }
        
        let string = WW.decimalTo4Hexadecimal() + CW.decimalTo4Hexadecimal() + R.decimalTo4Hexadecimal() +
            G.decimalTo4Hexadecimal() + B.decimalTo4Hexadecimal() + A.decimalTo4Hexadecimal()
        KLMLog(string)
        
        let parame = parameModel(dp: .PWM, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

    }
}

extension KLMTestViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? String, value == "FF"{
            SVProgressHUD.showError(withStatus: "超出功率")
        }
        KLMLog("success")
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

//extension KLMTestViewController: TuyaSmartDeviceDelegate {
//
//    func device(_ device: TuyaSmartDevice, dpsUpdate dps: [AnyHashable : Any]) {
//
//        if let value = dps["105"], value as! String == "FF" {
//
//            SVProgressHUD.showError(withStatus: "超出功率")
//
//        }
//    }
//}
