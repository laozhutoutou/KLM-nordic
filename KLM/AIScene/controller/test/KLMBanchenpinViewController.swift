//
//  KLMBanchenpinViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/25.
//

import UIKit

class KLMBanchenpinViewController: UIViewController {

    @IBOutlet weak var WWOK: UIButton!
    @IBOutlet weak var ROK: UIButton!
    @IBOutlet weak var GOK: UIButton!
    @IBOutlet weak var BOK: UIButton!
    
    @IBOutlet weak var BLEOK: UIButton!
    @IBOutlet weak var BLEFalse: UIButton!
    
    var OKBtnArray: [UIButton]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "蓝牙测试"

        OKBtnArray = [WWOK,ROK,GOK,BOK]
        
        BLEOK.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        
        
        BLEFalse.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        
        
        for btn in OKBtnArray {
            btn.isHidden = true
        }
        
    }
    
    @IBAction func startTest(_ sender: Any) {
        SVProgressHUD.show()
        let string = "0101"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    @IBAction func BLEResult(_ sender: UIButton) {
        
        
        if sender.isSelected {
            return
        }
        SVProgressHUD.show()
        sender.isSelected = true
        if sender.tag == 1 { //OK
            
            BLEFalse.isSelected = false
            let string = "0101"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            BLEOK.isSelected = false
            let string = "0100"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
}

extension KLMBanchenpinViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "010101" {
                WWOK.isHidden = false
            } else if value == "010102" {
                ROK.isHidden = false
            } else if value == "010103" {
                GOK.isHidden = false
            } else if value == "010104" {
                BOK.isHidden = false
                SVProgressHUD.dismiss()
                
            }
        }
        
        //合格或者不合格
        if message?.dp == .factoryTestResule {
            
            SVProgressHUD.showSuccess(withStatus: "测试完成")
            //重置节点
//            KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)
        }
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
        SVProgressHUD.showSuccess(withStatus: "测试完成")
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            NotificationCenter.default.post(name: .deviceReset, object: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
