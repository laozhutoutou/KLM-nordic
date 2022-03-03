//
//  KLMPassengerFlowViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/2/21.
//

import UIKit
import SVProgressHUD

class KLMPassengerFlowViewController: UIViewController {
    
    @IBOutlet weak var powerSwitch: UISwitch!
    @IBOutlet weak var passengerView: UIView!
    @IBOutlet weak var numLab: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        KLMSmartNode.sharedInstacnce.delegate = self
          
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "客流统计"
        
    }

    @IBAction func getPassenger(_ sender: Any) {
        
        SVProgressHUD.show()
        let parame = parameModel(dp: .passengerFlow)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMPassengerFlowViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp ==  .passengerFlow, let value = message?.value as? Int {//查询版本
            
            numLab.text = "\(value)"
            
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
