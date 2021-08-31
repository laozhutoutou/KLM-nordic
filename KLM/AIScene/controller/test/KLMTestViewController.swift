//
//  KLMTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/21.
//

import UIKit

class KLMTestViewController: UIViewController {
    
    var WW: Int = 0
    var R: Int = 0
    var G: Int = 0
    var B: Int = 0
    
    @IBOutlet weak var WWLab: UILabel!
    @IBOutlet weak var Rlab: UILabel!
    @IBOutlet weak var Glab: UILabel!
    @IBOutlet weak var Blab: UILabel!
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func value(_ sender: UISlider) {
        
        
        switch sender.tag {
        case 0:
            WW = Int(sender.value)
        case 1:
            R = Int(sender.value)
        case 2:
            G = Int(sender.value)
        case 3:
            B = Int(sender.value)
        default:
            break
        }
        
        let string = WW.decimalTo4Hexadecimal() + R.decimalTo4Hexadecimal() +
            G.decimalTo4Hexadecimal() + B.decimalTo4Hexadecimal()
        KLMLog(string)
        
        let parame = parameModel(dp: .PWM, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

    }
    
    @IBAction func valueChanged(_ sender: UISlider) {
        
        switch sender.tag {
        case 0:
            WWLab.text = "\(Int(sender.value))"
        
        case 1:
            Rlab.text = "\(Int(sender.value))"
        case 2:
            Glab.text = "\(Int(sender.value))"
        case 3:
            Blab.text = "\(Int(sender.value))"
        
        default:
            break
        }
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

