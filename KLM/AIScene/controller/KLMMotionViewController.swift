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
    @IBOutlet weak var doneBtn: UIButton!
    
    @IBOutlet weak var energySavingLab: UILabel!
    
    @IBOutlet weak var autoDimLab: UILabel!
    @IBOutlet weak var brightLab: UILabel!
    
    var timeSlider: KLMSlider!
    var lightSlider: KLMSlider!
    ///是否确认
    var isConfirm: Bool = false
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("Energy saving setting")
        
        view.backgroundColor = appBackGroupColor
        contentView.backgroundColor = appBackGroupColor
        
        timeContentView.layer.cornerRadius = 16
        lightContentView.layer.cornerRadius = 16
        
        doneBtn.layer.cornerRadius = 8
        doneBtn.backgroundColor = appMainThemeColor
        autoDim.onTintColor = appMainThemeColor
        
        setupUI()
        
        navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(dimiss)) as? [UIBarButtonItem]
        
        ///显示空白页面
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 5) {
            self.hideEmptyView()
        }
        
        energySavingLab.text = LANGLOC("Energy saving setting")
        autoDimLab.text = LANGLOC("Auto-dim(min)")
        brightLab.text = LANGLOC("Brightness")
        doneBtn.setTitle(LANGLOC("Confirm"), for: .normal)
    }
    
    private func setupUI() {
        
        contentView.isHidden = true
        
        //时间滑条
        let viewLeft: CGFloat = 20 + 16
        let sliderWidth = KLMScreenW - viewLeft * 2
        let timeSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: timeBgView.height), minValue: 1, maxValue: 60, step: 1)
        timeSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        timeSlider.currentValue = 1
        self.timeSlider = timeSlider
        timeBgView.addSubview(timeSlider)
        
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 1)
        lightSlider.getValueTitle = { value in
            
            return String(format: "%ld%%", Int(value))
        }
        lightSlider.delegate = self
        lightSlider.currentValue = 0
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
    }
    
    func setupData() {
        
        let parame = parameModel(dp: .deviceSetting)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    @IBAction func autoDimValue(_ sender: UISwitch) {
        
        if sender.isOn == false {
            
            SVProgressHUD.show()
            isConfirm = true
            //发送关闭指令
            let parame = parameModel(dp: .motion, value: "000000")
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        } else {
            
            contentView.isHidden = false
        }
    }
    
    @IBAction func Comfirm(_ sender: Any) {
        
        isConfirm = true
        SVProgressHUD.show()
        ///最后发送开指令
        let power = "01"
        let time = Int(self.timeSlider.currentValue).decimalTo2Hexadecimal()
        let light = Int(self.lightSlider.currentValue).decimalTo2Hexadecimal()
        let parame = parameModel(dp: .motion, value: power + time + light)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @objc func dimiss() {
        
        let parame = parameModel(dp: .motion, value: "040000")
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        dismiss(animated: true)
    }
}

extension KLMMotionViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .deviceSetting, let value = message?.value as? [UInt8] {
            
            ///节能开关
            let motion: Int = Int(value[4])
            self.autoDim.isOn = motion == 0 ? false : true
            contentView.isHidden = motion == 0 ? true : false
            
            ///亮度
            let light: Int = Int(value[5])
            self.lightSlider.currentValue = Float(light)
            
            ///时间
            let time: Int = Int(value[6])
            self.timeSlider.currentValue = Float(time)
            
            self.hideEmptyView()
        }
        
        if isConfirm == true {

            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            DispatchQueue.main.asyncAfter(deadline: 0.5) {
                self.dismiss(animated: true)
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        autoDim.isOn = true
        KLMShowError(error)
    }
}

extension KLMMotionViewController: KLMSliderDelegate {

    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        ///最后发送开指令
        let power = "03"
        let time = Int(self.timeSlider.currentValue).decimalTo2Hexadecimal()
        let light = Int(self.lightSlider.currentValue).decimalTo2Hexadecimal()
        let parame = parameModel(dp: .motion, value: power + time + light)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}



