//
//  KLMCMOSViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/6/10.
//

import UIKit

class KLMCMOSViewController: UIViewController {
    
    @IBOutlet weak var timeBgView: UIView!
    var timeSlider: KLMSlider!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    private func setupUI() {
        
        navigationItem.title = LANGLOC("Devicecoloursensing")
        
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
        let timeSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: timeBgView.height), minValue: 5, maxValue: 60, step: 1)
        timeSlider.getValueTitle = { value in
            
            return String(format: "%ld", Int(value))
        }
        timeSlider.currentValue = 5
        timeSlider.delegate = self
        self.timeSlider = timeSlider
        timeBgView.addSubview(timeSlider)
    }
}

extension KLMCMOSViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        let vv = Int(value)
        let parame = parameModel(dp: .colorTest, value: vv)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMCMOSViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp ==  .colorTest{
            
            //成功
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
