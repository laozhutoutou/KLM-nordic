//
//  KLMQudongTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/3/11.
//

import UIKit

class KLMQudongTestViewController: UIViewController {
    
    @IBOutlet weak var WBtn: UIButton!
    @IBOutlet weak var RBtn: UIButton!
    @IBOutlet weak var GBtn: UIButton!
    @IBOutlet weak var BBtn: UIButton!
    
    @IBOutlet weak var oneBtn: UIButton!
    @IBOutlet weak var twentyBtn: UIButton!
    @IBOutlet weak var hundredBtn: UIButton!
    
    @IBOutlet weak var stanbyOK: UIButton!
    
    var tongdaoBtnArray: [UIButton]!
    var tiaoguangBtnArray: [UIButton]!
    
    var tongdaoValue: Int = 1
    var tiaoguangValue: Int = 1
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "驱动测试"
        
        tongdaoBtnArray = [WBtn, RBtn, GBtn, BBtn]
        tiaoguangBtnArray = [oneBtn, twentyBtn ,hundredBtn]
        
        for btn in tongdaoBtnArray {
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.black.cgColor
            
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            
            btn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
            btn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        }
        
        for btn in tiaoguangBtnArray {
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.black.cgColor
            
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            
            btn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
            btn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        }
        
        stanbyOK.isHidden = true
        
        WBtn.isSelected = true
        oneBtn.isSelected = true
        
    }

    @IBAction func startTest(_ sender: Any) {
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "060A"  + tongdaoValue.decimalTo2Hexadecimal() + tiaoguangValue.decimalTo2Hexadecimal()
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    @IBAction func tongdaoClick(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        
        for btn in tongdaoBtnArray {
            btn.isSelected = false
        }
        sender.isSelected = true
        tongdaoValue = sender.tag
    }
    
    @IBAction func tiaoguang(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        
        for btn in tiaoguangBtnArray {
            btn.isSelected = false
        }
        sender.isSelected = true
        tiaoguangValue = sender.tag
    }
    
    @IBAction func reset(_ sender: UIButton) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        //重置节点
        KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)
    }
    
    @IBAction func stanbyClick(_ sender: Any) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0609"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMQudongTestViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .factoryTest, let value = message?.value as? String {
            
            if value.contains("060A") {
                SVProgressHUD.showSuccess(withStatus: "发送成功")
            }
            
        }
        
        //待机功耗
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "0609"{
                SVProgressHUD.dismiss()
                stanbyOK.isHidden = false
            }
        }
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        SVProgressHUD.showSuccess(withStatus: "复位成功")
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            NotificationCenter.default.post(name: .deviceReset, object: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
