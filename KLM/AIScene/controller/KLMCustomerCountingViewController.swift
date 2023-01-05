//
//  KLMCustomerCountingViewController.swift
//  KLM
//
//  Created by 朱雨 on 2023/1/4.
//

import UIKit

class KLMCustomerCountingViewController: UIViewController, Editable {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Customer Counting")
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 1) {
            self.hideEmptyView()
        }
    }
    
    private func setupData() {
        
        let parame = parameModel(dp: .powerSetting)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMCustomerCountingViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .powerSetting, let value = message?.value as? Int {
            if message?.opCode == .read {
                
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
