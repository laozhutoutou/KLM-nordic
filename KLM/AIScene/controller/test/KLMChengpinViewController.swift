//
//  KLMChengpinViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/26.
//

import UIKit

class KLMChengpinViewController: UIViewController {
    
    @IBOutlet weak var WWOK: UIButton!
    @IBOutlet weak var ROK: UIButton!
    @IBOutlet weak var GOK: UIButton!
    @IBOutlet weak var BOK: UIButton!
    
    @IBOutlet weak var WWFalse: UIButton!
    @IBOutlet weak var RFalse: UIButton!
    @IBOutlet weak var GFalse: UIButton!
    @IBOutlet weak var BFalse: UIButton!
    
    @IBOutlet weak var heibuOKBtn: UIButton!
    @IBOutlet weak var heibufalseBtn: UIButton!
    
    @IBOutlet weak var sekaOKBtn: UIButton!
    @IBOutlet weak var sekafalseBtn: UIButton!
    
    var OKBtnArray: [UIButton]!
    var falseBtnArray: [UIButton]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "成品测试"

        OKBtnArray = [WWOK,ROK,GOK,BOK,heibuOKBtn,sekaOKBtn]
        falseBtnArray = [WWFalse,RFalse,GFalse,BFalse,heibufalseBtn,sekafalseBtn]
        
        for btn in OKBtnArray {
            btn.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        }
        
        for btn in falseBtnArray {
            btn.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        }
    }
    
    //测试BLE
    @IBAction func test(_ sender: UIButton) {
        let type = sender.tag.decimalTo2Hexadecimal()
        let string = "0102" + type
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    //测试MCU
    @IBAction func testMCU(_ sender: UIButton) {
        let type = sender.tag.decimalTo2Hexadecimal()
        let string = "0202" + type
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
            let string = "0102" + type + "01"
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
            let string = "0102" + type + "00"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        case 9://黑布合格
            heibufalseBtn.isSelected = false
            let string = "02020201"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        case 11://黑布不合格
            heibuOKBtn.isSelected = false
            let string = "02020200"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        case 10://色卡合格
            sekafalseBtn.isSelected = false
            let string = "02020301"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        case 12://色卡不合格
            sekaOKBtn.isSelected = false
            let string = "02020300"
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

extension KLMChengpinViewController: KLMSmartNodeDelegate {
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
        SVProgressHUD.showSuccess(withStatus: "重置成功")
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            NotificationCenter.default.post(name: .deviceReset, object: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
