//
//  KLMBaoZhuangTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/31.
//

import UIKit

class KLMBaoZhuangTestViewController: UIViewController {
    
    @IBOutlet weak var WWOK: UIButton!
    @IBOutlet weak var ROK: UIButton!
    @IBOutlet weak var GOK: UIButton!
    @IBOutlet weak var BOK: UIButton!
    
    @IBOutlet weak var heibuOK: UIButton!
    @IBOutlet weak var sekaOK: UIButton!
    @IBOutlet weak var stanbyOK: UIButton!
    
    @IBOutlet weak var OKBtn: UIButton!
    @IBOutlet weak var falseBtn: UIButton!
    
    var OKBtnArray: [UIButton]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "包装测试"
        
        OKBtnArray = [WWOK,ROK,GOK,BOK,heibuOK,sekaOK,stanbyOK]
        
        OKBtn.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        falseBtn.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        
        for btn in OKBtnArray {
            btn.isHidden = true
        }
        
    }
    
    @IBAction func startTest(_ sender: Any) {
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0501"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    @IBAction func chengpinResult(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        sender.isSelected = true
        if sender.tag == 1 { //OK
            
            falseBtn.isSelected = false
            let string = "0501"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            OKBtn.isSelected = false
            let string = "0500"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
    
    @IBAction func heibu(_ sender: Any) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0503"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func seka(_ sender: Any) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0504"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func stanbyClick(_ sender: Any) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0509"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMBaoZhuangTestViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? String, message?.dp == .factoryTest {
            if value == "050101" {
                WWOK.isHidden = false
            } else if value == "050102" {
                ROK.isHidden = false
            } else if value == "050103" {
                GOK.isHidden = false
            } else if value == "050104" {
                BOK.isHidden = false
                SVProgressHUD.dismiss()
                
            }
        }
        
        //黑布
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "0503"{
                SVProgressHUD.dismiss()
                heibuOK.isHidden = false
            }
        }
        
        //色卡
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "0504"{
                SVProgressHUD.dismiss()
                sekaOK.isHidden = false
            }
        }
        
        //待机功耗
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "0509"{
                SVProgressHUD.dismiss()
                stanbyOK.isHidden = false
            }
        }
        
        //合格或者不合格
        if message?.dp == .factoryTestResule {
//            SVProgressHUD.showSuccess(withStatus: "测试完成")
            //重置节点
            KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)
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

