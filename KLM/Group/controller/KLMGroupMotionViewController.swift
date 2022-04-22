//
//  KLMGroupMotionViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/3/7.
//

import UIKit

class KLMGroupMotionViewController: UIViewController {

    @IBOutlet weak var onBtn: UIButton!
    @IBOutlet weak var offBtn: UIButton!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var timeContentView: UIView!
    @IBOutlet weak var timeBgView: UIView!
    
    @IBOutlet weak var lightContentView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    
    var timeSlider: KLMSlider!
    var lightSlider: KLMSlider!
    
    var groupData: GroupData = GroupData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Energysavingsettings")
        
        view.backgroundColor = appBackGroupColor
        contentView.backgroundColor = appBackGroupColor
        
        timeContentView.layer.cornerRadius = 16
        lightContentView.layer.cornerRadius = 16
        
        onBtn.layer.cornerRadius = 4.0
        offBtn.layer.cornerRadius = 4.0
        onBtn.clipsToBounds = true
        offBtn.clipsToBounds = true
        
        onBtn.layer.borderWidth = 1
        offBtn.layer.borderWidth = 1
        
        onBtn.layer.borderColor = UIColor.lightGray.cgColor
        offBtn.layer.borderColor = UIColor.lightGray.cgColor
        
        onBtn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
        onBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        
        offBtn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
        offBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        
        setupUI()
        
        setupData()
    }
    
    private func setupUI() {
        
        //时间滑条
        let viewLeft: CGFloat = 20 + 16
        let sliderWidth = KLMScreenW - viewLeft * 2
        let timeSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: timeBgView.height), minValue: 1, maxValue: 60, step: 2)
        timeSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        timeSlider.currentValue = 1
        self.timeSlider = timeSlider
        timeBgView.addSubview(timeSlider)
        
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 5)
        lightSlider.getValueTitle = { value in
            
            return String(format: "%ld%%", Int(value))
        }
        lightSlider.currentValue = 0
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
    }
    
    private func setupData() {
        
        var address: Int = 0
        if KLMHomeManager.sharedInstacnce.controllType == .Group {
            address = Int(KLMHomeManager.currentGroup.address.address)
            
            SVProgressHUD.show()
            KLMService.selectGroup(groupId: address) { response in
                SVProgressHUD.dismiss()
                guard let model = response as? GroupData else { return  }
                self.groupData = model
                //UI
                if self.groupData.energyPower == 0 {
                    self.offBtn.isSelected = true
                    self.contentView.isHidden = true
                } else {
                    self.onBtn.isSelected = true
                    self.contentView.isHidden = false
                }
                
                ///亮度
                let light: Int = self.groupData.brightness
                self.lightSlider.currentValue = Float(light)

                ///时间
                let time: Int = self.groupData.autoDim
                self.timeSlider.currentValue = Float(time)
                
            } failure: { error in
                KLMHttpShowError(error)
            }
        }
        
        
    }
    
    private func sendData() {
        
        var address: Int = 0
        if KLMHomeManager.sharedInstacnce.controllType == .Group {
            address = Int(KLMHomeManager.currentGroup.address.address)
            
            KLMService.updateGroup(groupId: address, groupData: self.groupData) { response in
                
            } failure: { error in
                
            }
        }
        
    }

    @IBAction func onClick(_ sender: Any) {
        
        if onBtn.isSelected {
            return
        }
        
        onBtn.isSelected = true
        offBtn.isSelected = false
        
        contentView.isHidden = false
    }
    
    @IBAction func offClick(_ sender: Any) {
        
        if offBtn.isSelected {
            return
        }
                
        SVProgressHUD.show()
        //发送关闭指令
        let parame = parameModel(dp: .motionPower, value: 0)
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                self.contentView.isHidden = true
                self.onBtn.isSelected = false
                self.offBtn.isSelected = true
            } failure: { error in
                
                KLMShowError(error)
            }
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                self.contentView.isHidden = true
                self.onBtn.isSelected = false
                self.offBtn.isSelected = true
                
                self.groupData.energyPower = 0
                self.sendData()
                
            } failure: { error in
                KLMShowError(error)
            }
        }
    }
    
    @IBAction func Comfirm(_ sender: Any) {
        
        SVProgressHUD.show()
        ///最后发送开指令
        let parameLight = parameModel(dp: .motionLight, value: Int(self.lightSlider.currentValue))
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parameLight) {
                
                print("success")
                
            } failure: { error in
                
                KLMShowError(error)
            }
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parameLight, toGroup: KLMHomeManager.currentGroup) {
                
                print("success")
                
            } failure: { error in
                KLMShowError(error)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            
            let parameTime = parameModel(dp: .motionTime, value: Int(self.timeSlider.currentValue))
            if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
                
                KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parameTime) {
                    
                    print("success")
                    
                } failure: { error in
                    
                    KLMShowError(error)
                }
                
            } else {
                
                KLMSmartGroup.sharedInstacnce.sendMessage(parameTime, toGroup: KLMHomeManager.currentGroup) {
                    
                    print("success")
                    
                } failure: { error in
                    KLMShowError(error)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: 0.5) {
                
                let parameOn = parameModel(dp: .motionPower, value: 1)
                if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
                    
                    KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parameOn) {
                        
                        print("success")
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                        
                        DispatchQueue.main.asyncAfter(deadline: 0.5) {
                            self.navigationController?.popViewController(animated: true)
                        }
                        
                    } failure: { error in
                        
                        KLMShowError(error)
                    }
                } else {
                    
                    KLMSmartGroup.sharedInstacnce.sendMessage(parameOn, toGroup: KLMHomeManager.currentGroup) {
                        
                        print("success")
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                        
                        self.groupData.energyPower = 1
                        self.groupData.brightness = Int(self.lightSlider.currentValue)
                        self.groupData.autoDim = Int(self.timeSlider.currentValue)
                        self.sendData()
                        
                        DispatchQueue.main.asyncAfter(deadline: 0.5) {
                            self.navigationController?.popViewController(animated: true)
                        }
                        
                    } failure: { error in
                        KLMShowError(error)
                    }
                    
                }
                
            }
        }
    }
}
