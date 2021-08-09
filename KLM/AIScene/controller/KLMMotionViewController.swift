//
//  KLMMotionViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/5.
//

import UIKit

class KLMMotionViewController: UIViewController {

    @IBOutlet weak var timeContentView: UIView!
    @IBOutlet weak var timeBgView: UIView!
    
    @IBOutlet weak var lightContentView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    
    var timeSlider: KLMSlider!
    var lightSlider: KLMSlider!
    
    var isAllNodes: Bool = false
    
    /// 是否已经读取
    var motionTimeFirst = true
    var motionLightFirst = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        if isAllNodes == false {
            
            setupData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isAllNodes {
            
            navigationItem.title = LANGLOC("allDeviceAutoEnergysaving")
            
        } else {
            
            navigationItem.title = LANGLOC("Energysavingsettings")
        }
        
        
        view.backgroundColor = appBackGroupColor
        timeContentView.layer.cornerRadius = 16
        lightContentView.layer.cornerRadius = 16
        
        setupUI()
        
    }
    
    func setupUI() {
        
        //时间滑条
        let viewLeft: CGFloat = 20 + 16
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
    }
    
    func setupData() {
        
        let parameTime = parameModel(dp: .AllDp)
        KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
        
    }
}

extension KLMMotionViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp ==  .motionTime{
            if motionTimeFirst {
                motionTimeFirst = false
                let value = message?.value as! Int
                self.timeSlider.currentValue = Float(value)
            }
            
        } else if message?.dp ==  .motionLight{
            if motionLightFirst {
                motionLightFirst = false
                let value = message?.value as! Int
                self.lightSlider.currentValue = Float(value)
            }
        }
        KLMLog("success")
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMMotionViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        if slider == self.lightSlider {
            
            let parame = parameModel(dp: .motionLight, value: Int(self.lightSlider.currentValue))
            
            if isAllNodes {
                
                KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {
                    
                    print("success")
                    
                } failure: { error in
                    
                    KLMShowError(error)
                }
                
            } else {
                
                
                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            }
            
        } else {
            
            let parame = parameModel(dp: .motionTime, value: Int(self.timeSlider.currentValue))
            
            if isAllNodes {
                
                KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {
                    
                    print("success")
                    
                } failure: { error in
                    
                    KLMShowError(error)
                }
                
            } else {
                
                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            }
            
        }
    }
}


