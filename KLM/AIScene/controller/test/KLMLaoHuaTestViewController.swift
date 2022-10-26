//
//  KLMLaoHuaTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/31.
//

import UIKit

class KLMLaoHuaTestViewController: UIViewController {
    
    @IBOutlet weak var shichan1OK: UIButton!
    @IBOutlet weak var shichan2OK: UIButton!
    
    @IBOutlet weak var OKBtn: UIButton!
    @IBOutlet weak var falseBtn: UIButton!
    
    var OKBtnArray: [UIButton]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "老化测试"

        OKBtnArray = [shichan1OK,shichan2OK]
        
        OKBtn.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        falseBtn.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        
        for btn in OKBtnArray {
            btn.isHidden = true
        }
        
    }
    
    @IBAction func laohuaResult(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        sender.isSelected = true
        if sender.tag == 1 { //OK
            
            falseBtn.isSelected = false
            let string = "0401"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            OKBtn.isSelected = false
            let string = "0400"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
    
    @IBAction func shichan1(_ sender: Any) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0406"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func shichan2(_ sender: Any) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0407"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMLaoHuaTestViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        //试产1
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "0406"{
                SVProgressHUD.dismiss()
                shichan1OK.isHidden = false
            }
        }
        
        //试产2
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "0407"{
                SVProgressHUD.dismiss()
                shichan2OK.isHidden = false
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
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
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

