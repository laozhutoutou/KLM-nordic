//
//  KLMDFUViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/17.
//

import UIKit

class KLMDFUViewController: UIViewController {
    
    var dataPackageArray: [String]!
    var currentIndex = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataPackageArray = KLMUpdateManager.sharedInstacnce.dealFirmware()
        
    }

    @IBAction func DFU(_ sender: Any) {
        
//        SVProgressHUD.showProgress(0)
//        SVProgressHUD.setDefaultMaskType(.black)
        
        let first = KLMUpdateManager.sharedInstacnce.getUpdateFirstPackage()
        let parame = parameModel(dp: .checkVersion, value: first)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentConnectNode!)
        
    }
}

extension KLMDFUViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? String, value == "FF"{
            
            if currentIndex >= dataPackageArray.count {
                //发送完成
                SVProgressHUD.showSuccess(withStatus: "Update complete")
                DispatchQueue.main.asyncAfter(deadline: 1) {
                    self.navigationController?.popViewController(animated: true)
                }
                return
            }
//                let progress: Float = Float(currentIndex) / Float(dataPackageArray.count)
//                SVProgressHUD.showProgress(progress)
            
            let package = dataPackageArray[currentIndex]
            let parame = parameModel(dp: .DFU, value: package)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentConnectNode!)
            KLMLog("------------------\(currentIndex)")
            currentIndex += 1
            
        } else {
            
            //错误
            SVProgressHUD.showError(withStatus: "error")
            DispatchQueue.main.asyncAfter(deadline: 1) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
        DispatchQueue.main.asyncAfter(deadline: 1) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
