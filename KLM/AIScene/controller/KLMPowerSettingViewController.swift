//
//  KLMPowerSettingViewController.swift
//  KLM
//
//  Created by 朱雨 on 2023/1/3.
//

import UIKit

class KLMPowerSettingViewController: UIViewController, Editable {

    @IBOutlet weak var powerBgView: UIView!
    var powerValue: Int = 30 {
        didSet {
            powerSlider.currentValue = Float(powerValue)
        }
    }
    var powerSlider: KLMSlider!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        navigationItem.title = LANGLOC("Power setting")
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 1) {
            self.hideEmptyView()
        }
    }

    private func setupUI() {
        
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
        
        //亮度滑条
        let powerSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: powerBgView.height), minValue: 5, maxValue: 30, step: 1)
        powerSlider.getValueTitle = { value in

            return String(format: "%ldW", Int(value))
        }
        powerSlider.currentValue = Float(powerValue)
        powerSlider.delegate = self
        self.powerSlider = powerSlider
        powerBgView.addSubview(powerSlider)
    }
    
    private func setupData() {
        
        let parame = parameModel(dp: .powerSetting)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMPowerSettingViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .powerSetting, let value = message?.value as? Int {
            if message?.opCode == .read {
                powerValue = value
            } else {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMPowerSettingViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        let power = Int(value)
        let parame = parameModel(dp: .powerSetting, value: power)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}
