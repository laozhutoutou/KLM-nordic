//
//  KLMMotionViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/5.
//

import UIKit

class KLMMotionViewController: UIViewController, Editable {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var timeContentView: UIView!
    @IBOutlet weak var timeBgView: UIView!
    
    @IBOutlet weak var lightContentView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    
    @IBOutlet weak var autoDim: UISwitch!
    
    var timeSlider: KLMSlider!
    var lightSlider: KLMSlider!
    
    var isAllNodes: Bool = false
    
    /// 是否已经读取
    var motionTimeFirst = true
    var motionLightFirst = true
    
    var isClickComfirm = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("Energysavingsettings")
        
        view.backgroundColor = appBackGroupColor
        contentView.backgroundColor = appBackGroupColor
        
        timeContentView.layer.cornerRadius = 16
        lightContentView.layer.cornerRadius = 16
        
        setupUI()
        
        ///显示空白页面
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 1) {
            self.hideEmptyView()
        }
    }
    
    func setupUI() {
        
        contentView.isHidden = true
        
        //时间滑条
        let viewLeft: CGFloat = 20 + 16
        let sliderWidth = KLMScreenW - viewLeft * 2
        let timeSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: timeBgView.height), minValue: 1, maxValue: 60, step: 2)
        timeSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        timeSlider.delegate = self
        timeSlider.currentValue = 1
        self.timeSlider = timeSlider
        timeBgView.addSubview(timeSlider)
        
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 5)
        lightSlider.getValueTitle = { value in
            
            return String(format: "%ld%%", Int(value))
        }
        lightSlider.delegate = self
        lightSlider.currentValue = 0
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
    }
    
    func setupData() {
        
        if isAllNodes == false {
            
            let parameTime = parameModel(dp: .AllDp)
            KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
        } else {
            //填充本地数据
            if let motionPower = KLMGetUserDefault("motionPower") as? Int, motionPower == 1  {
                self.contentView.isHidden = false
                self.autoDim.isOn =  true
                
            }
            guard let motionTime = KLMGetUserDefault("motionTime") as? Int else {
                return
            }
            
            guard let motionLight = KLMGetUserDefault("motionLight") as? Int else {
                return
            }
            
            self.timeSlider.currentValue = Float(motionTime)
            self.lightSlider.currentValue = Float(motionLight)
        }
        
    }
    
    @IBAction func autoDimValue(_ sender: UISwitch) {
        
        if sender.isOn == false {
            
            SVProgressHUD.show()
            //发送关闭指令
            let parame1 = parameModel(dp: .motionPower, value: 0)
            if isAllNodes {
                
                KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame1) {
                    SVProgressHUD.dismiss()
                    //存储在本地
                    KLMSetUserDefault("motionPower", 0)
                    self.contentView.isHidden = true
                    
                } failure: { error in
                    
                    KLMShowError(error)
                }
                
            } else {
                
                KLMSmartNode.sharedInstacnce.sendMessage(parame1, toNode: KLMHomeManager.currentNode)
            }
        } else {
            
            contentView.isHidden = false
        }
    }
    
    @IBAction func Comfirm(_ sender: Any) {
        
        SVProgressHUD.show()
        ///最后发送开指令
        let parameLight = parameModel(dp: .motionLight, value: Int(self.lightSlider.currentValue))
        if self.isAllNodes {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parameLight) {
                
                print("success")
                KLMSetUserDefault("motionLight", Int(self.lightSlider.currentValue))
                
            } failure: { error in
                
                KLMShowError(error)
            }
            
        } else {
            
            KLMSmartNode.sharedInstacnce.sendMessage(parameLight, toNode: KLMHomeManager.currentNode)
        }
        
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            
            let parameTime = parameModel(dp: .motionTime, value: Int(self.timeSlider.currentValue))
            if self.isAllNodes {
                
                KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parameTime) {
                    
                    print("success")
                    //存储当前设定值
                    KLMSetUserDefault("motionTime", Int(self.timeSlider.currentValue))
                    
                } failure: { error in
                    
                    KLMShowError(error)
                }
                
            } else {
                
                KLMSmartNode.sharedInstacnce.sendMessage(parameTime, toNode: KLMHomeManager.currentNode)
            }
            
            DispatchQueue.main.asyncAfter(deadline: 0.5) {
                
                let parameOn = parameModel(dp: .motionPower, value: 1)
                if self.isAllNodes {
                    
                    KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parameOn) {
                        
                        print("success")
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                        KLMSetUserDefault("motionPower", 1)
                        
                        DispatchQueue.main.asyncAfter(deadline: 0.5) {
                            self.navigationController?.popViewController(animated: true)
                        }
                        
                    } failure: { error in
                        
                        KLMShowError(error)
                    }
                } else {
                    self.isClickComfirm = true
                    KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: KLMHomeManager.currentNode)
                }
                
            }
        }
    }
}

extension KLMMotionViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
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
        } else if message?.dp ==  .motionPower{
            
            let value = message?.value as! Int
            self.autoDim.isOn = value == 0 ? false : true
            contentView.isHidden = value == 0 ? true : false
        }
        KLMLog("success")
        
        //单设备确定
        if isClickComfirm {
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            DispatchQueue.main.asyncAfter(deadline: 0.5) {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMMotionViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
    }
}


