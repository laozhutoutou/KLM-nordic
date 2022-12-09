//
//  KLMCheckVersionTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/12/8.
//

import UIKit

class KLMCheckVersionTestViewController: UIViewController {

    @IBOutlet weak var sectionLab: UILabel!
    @IBOutlet weak var encryptionLab: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    @IBAction func fenqu(_ sender: Any) {
        
        SVProgressHUD.show()
        let parame = parameModel(dp: .fenqu)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func encryption(_ sender: Any) {
        
        SVProgressHUD.show()
        let parame = parameModel(dp: .encryption)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMCheckVersionTestViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.opCode == .read {
            if message?.dp == .fenqu, let value: Int = message?.value as? Int {
                if value == 0 {
                    sectionLab.text = "0x20000"
                } else if value == 1 {
                    sectionLab.text = "0x40000"
                }
            }
            
            if message?.dp == .encryption, let value: Int = message?.value as? Int {
                if value == 0 {
                    encryptionLab.text = "未加密"
                } else if value == 1 {
                    encryptionLab.text = "已加密"
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
