//
//  KLMPCBASensorViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/31.
//

import UIKit

class KLMPCBASensorViewController: UIViewController {
    
    @IBOutlet weak var WWOK: UIButton!
    @IBOutlet weak var ROK: UIButton!
    @IBOutlet weak var GOK: UIButton!
    @IBOutlet weak var BOK: UIButton!
    
    @IBOutlet weak var BLEOK: UIButton!
    @IBOutlet weak var BLEFalse: UIButton!
    
    
    @IBOutlet weak var OKBtn: UIButton!
    @IBOutlet weak var falseBtn: UIButton!
    @IBOutlet weak var MCUView: UIView!
    
    var OKBtnArray: [UIButton]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "sensor测试"

        OKBtnArray = [WWOK,ROK,GOK,BOK,OKBtn]
        
        BLEOK.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        OKBtn.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        
        BLEFalse.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        falseBtn.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        
        for btn in OKBtnArray {
            btn.isHidden = true
        }
        MCUView.isHidden = true
        BLEOK.isHidden = true
        BLEFalse.isHidden = true
    }
    
    @IBAction func startTest(_ sender: Any) {
        SVProgressHUD.show()
        let string = "0201"
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
            let string = "020101"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            BLEOK.isSelected = false
            let string = "020100"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
    
    @IBAction func MCUResult(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        SVProgressHUD.show()
        sender.isSelected = true
        if sender.tag == 1 { //OK
            
            falseBtn.isSelected = false
            let string = "020201"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            OKBtn.isSelected = false
            let string = "020200"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
    
    @IBAction func openCamera(_ sender: Any) {
        
        SVProgressHUD.show()
        let string = "0202"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMPCBASensorViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "020101" {
                WWOK.isHidden = false
            } else if value == "020102" {
                ROK.isHidden = false
            } else if value == "020103" {
                GOK.isHidden = false
            } else if value == "020104" {
                BOK.isHidden = false
                SVProgressHUD.dismiss()
                BLEOK.isHidden = false
                BLEFalse.isHidden = false
            }
        }
        
        //合格或者不合格
        if let value = message?.value as? String, message?.dp == .factoryTestResule {
            
            if value == "020100" || value == "020101"{
                SVProgressHUD.dismiss()
                MCUView.isHidden = false
            }
        }
        
        //打开图像
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "020200" || value == "020201"{
                SVProgressHUD.dismiss()
                
            }
        }
        
        //正常或者不正常
        if let value = message?.value as? String, message?.dp == .factoryTestResule {
            
            if value == "020200" || value == "020201"{
                //重置节点
                KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)
            }
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
