//
//  KLMMotionViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/5.
//

import UIKit

class KLMMotionViewController: UIViewController {

    @IBOutlet weak var timeBgView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    
    var timeSlider: KLMSlider!
    var lightSlider: KLMSlider!
    
    var isFirstTime = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Motion"
        
        //时间滑条
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
        let timeSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: timeBgView.height), minValue: 0, maxValue: 60, step: 2)
        timeSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        timeSlider.delegate = self
        self.timeSlider = timeSlider
        timeBgView.addSubview(timeSlider)
        
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 5)
        lightSlider.getValueTitle = { value in
            
            return String(format: "%ld%%", Int(value))
        }
        lightSlider.delegate = self
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {
            
            setupData()
        }
    }
    
    func setupData() {
        
        ///查询设备信息
        var dict2 = Dictionary<String,AnyObject>()
        dict2["1"] = NSNull()
        
//        KLMHomeManager.currentNode.sendMessage(dpCode: <#T##Int#>, parameters: <#T##String#>)(dict2) {
//
//        } failure: { (error) in
//            KLMLog(error)
//        }
    }
}

extension KLMMotionViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        if slider == self.lightSlider {
                    
            let parame = parameModel(dp: .motionLight, value: Int(self.lightSlider.currentValue))
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode) {_ in 
                
            } failure: { error in
                KLMShowError(error)
            }

            
        } else {
            
            let parame = parameModel(dp: .motionTime, value: Int(self.timeSlider.currentValue))
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode) {_ in 
                print("success")
            } failure: { error in
                KLMShowError(error)
            }
            
        }
        
    }
}
