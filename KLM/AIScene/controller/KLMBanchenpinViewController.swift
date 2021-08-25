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
    
    @IBOutlet weak var WWFalse: UIButton!
    @IBOutlet weak var RFalse: UIButton!
    @IBOutlet weak var GFalse: UIButton!
    @IBOutlet weak var BFalse: UIButton!
    
    @IBOutlet weak var OKBtn: UIButton!
    @IBOutlet weak var falseBtn: UIButton!
    
    var OKBtnArray: [UIButton]!
    var falseBtnArray: [UIButton]!
    
    var isReset: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "半成品测试"
        
        navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(back)) as? [UIBarButtonItem]

        OKBtnArray = [WWOK,ROK,GOK,BOK,OKBtn]
        falseBtnArray = [WWFalse,RFalse,GFalse,BFalse,falseBtn]
        
        for btn in OKBtnArray {
            btn.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        }
        
        for btn in falseBtnArray {
            btn.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        }
    }
    
    @objc func back() {
        
        if isReset == false {
            SVProgressHUD.showInfo(withStatus: "请点击重置按钮")
            return
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    //测试
    @IBAction func test(_ sender: UIButton) {
        let type = sender.tag.decimalTo2Hexadecimal()
        let string = "0101" + type
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    //测试结果
    @IBAction func result(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        
        sender.isSelected = true
        
        switch sender.tag {
        case 1,2,3,4://ww等合格
            for btn in falseBtnArray {
                if btn.tag - 4 == sender.tag {
                    btn.isSelected = false
                    break
                }
            }
            
            let type = sender.tag.decimalTo2Hexadecimal()
            let string = "0101" + type + "01"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        case 5,6,7,8://ww等不合格
            for btn in OKBtnArray {
                if sender.tag - 4 == btn.tag {
                    btn.isSelected = false
                    break
                }
            }
            let type = (sender.tag - 4).decimalTo2Hexadecimal()
            let string = "0101" + type + "00"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        case 9://图像合格
            falseBtn.isSelected = false
            let string = "02010101"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        case 10://图像不合格
            OKBtn.isSelected = false
            let string = "02010100"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        default:
            break
        }
        
        
    }
    
    @IBAction func reset(_ sender: Any) {
        
        SVProgressHUD.show()
        KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)
        
    }
    
}

extension KLMBanchenpinViewController: KLMSmartNodeDelegate {
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
        isReset = true
        SVProgressHUD.showSuccess(withStatus: "重置成功")
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            NotificationCenter.default.post(name: .deviceReset, object: nil)
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
