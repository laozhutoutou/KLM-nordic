//
//  KLMBrightnessViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/30.
//

import UIKit

class KLMBrightnessViewController: UIViewController, Editable {
    
    @IBOutlet weak var lightBgView: UIView!
    var lightValue: Int = 100 {
        didSet {
            lightSlider.currentValue = Float(lightValue)
        }
    }
    var lightSlider: KLMSlider!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()

        navigationItem.title = LANGLOC("Brightness")
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 1) {
            self.hideEmptyView()
        }
    }
    
    private func setupUI() {
        
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
        
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 1)
        lightSlider.getValueTitle = { value in

            return String(format: "%ld%%", Int(value))
        }
        lightSlider.currentValue = Float(lightValue)
        lightSlider.delegate = self
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
    }
    
    private func setupData() {
        
        let parame = parameModel(dp: .brightness)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMBrightnessViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .brightness, let value = message?.value as? Int {
            if message?.opCode == .read {
                lightValue = value
            } else {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMBrightnessViewController: KLMSliderDelegate {

    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        let light = Int(value)
        let parame = parameModel(dp: .brightness, value: light)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}
