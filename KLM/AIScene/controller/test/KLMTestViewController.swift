//
//  KLMTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/21.
//

import UIKit

class KLMTestViewController: UIViewController {
    
    var WW: Int = 0
    var R: Int = 0
    var G: Int = 0
    var B: Int = 0
    
    @IBOutlet weak var WWView: UIView!
    @IBOutlet weak var Rview: UIView!
    @IBOutlet weak var gView: UIView!
    @IBOutlet weak var BView: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
        let wwSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: WWView.height), minValue: 0, maxValue: 1000, step: 1)
        wwSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        wwSlider.tag = 0
        wwSlider.delegate = self
        wwSlider.currentValue = 0
        WWView.addSubview(wwSlider)
        
        let RSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: WWView.height), minValue: 0, maxValue: 1000, step: 1)
        RSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        RSlider.tag = 1
        RSlider.currentValue = 0
        RSlider.delegate = self
        Rview.addSubview(RSlider)
        
        let GSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: WWView.height), minValue: 0, maxValue: 1000, step: 1)
        GSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        GSlider.tag = 2
        GSlider.currentValue = 0
        GSlider.delegate = self
        gView.addSubview(GSlider)
        
        let BSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: WWView.height), minValue: 0, maxValue: 1000, step: 1)
        BSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        BSlider.tag = 3
        BSlider.currentValue = 0
        BSlider.delegate = self
        BView.addSubview(BSlider)
    }
    
}

extension KLMTestViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? String, value == "FF"{
            SVProgressHUD.showInfo(withStatus: "超出功率")
        }
        KLMLog("success")
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMTestViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        switch slider.tag {
        case 0:
            WW = Int(value)
        case 1:
            R = Int(value)
        case 2:
            G = Int(value)
        case 3:
            B = Int(value)
        default:
            break
        }
    
        let string = WW.decimalTo4Hexadecimal() + R.decimalTo4Hexadecimal() +
            G.decimalTo4Hexadecimal() + B.decimalTo4Hexadecimal()
        KLMLog(string)
        
        let parame = parameModel(dp: .PWM, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }

}

