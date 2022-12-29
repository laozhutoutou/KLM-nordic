//
//  KLMDaliViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/12/29.
//

import UIKit

private struct tempColors {
    let maxTemp: Float = 2000
    let minTemp: Float = 10000
}

class KLMDaliViewController: UIViewController, Editable {
    
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var colorTempBgView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    
    @IBOutlet weak var colorTempLab: UILabel!
    @IBOutlet weak var brightLab: UILabel!
    
    var colorTempValue: Int = 6
    var lightValue: Int = 100
    
    var colorTempSlider: KLMSlider!
    var lightSlider: KLMSlider!
    
    private let colorTemp = tempColors()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.layer.cornerRadius = 16
        
        setupUI()
        
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 1) {
            self.hideEmptyView()
        }
    }
    
    func setupUI() {
        
        view.backgroundColor = appBackGroupColor
        
        ///色温滑条
        let viewLeft: CGFloat = 20 + 16
        let sliderWidth = KLMScreenW - viewLeft * 2
    
        let colorTempSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: colorTempBgView.height), minValue: 0, maxValue: 10, step: 1)
        colorTempSlider.indicateViewWidth = 50
        colorTempSlider.getValueTitle = {[weak self] value in
            guard let self = self else { return ""}
            let vv = Int(value)
            let vvv = vv * 100 + Int(self.colorTemp.minTemp)
            return String(format: "%ldK", vvv)
        }
        colorTempSlider.delegate = self
        self.colorTempSlider = colorTempSlider
        colorTempBgView.addSubview(colorTempSlider)
        
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 1, maxValue: 100, step: 1)
        lightSlider.getValueTitle = { value in

            return String(format: "%ld%%", Int(value))
        }
        lightSlider.delegate = self
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
        
        colorTempLab.text = LANGLOC("Colour temperature")
        brightLab.text = LANGLOC("Brightness")
    }
    
    private func setupData() {
        
        let parame = parameModel(dp: .AllDp)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }

}

extension KLMDaliViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        if message?.dp ==  .colorTemp, message?.opCode == .read{//色温
            
            let value = message?.value as! Int
            colorTempValue = value
            self.colorTempSlider.currentValue = Float(colorTempValue)
            
        } else if message?.dp ==  .light, message?.opCode == .read { //亮度
            
            let value = message?.value as! Int
            lightValue = value
            self.lightSlider.currentValue = Float(lightValue)
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        
        KLMShowError(error)
    }
}

extension KLMDaliViewController: KLMSliderDelegate {

    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        if slider == colorTempSlider {//色温
            let vv = Int(value)
            let parame = parameModel(dp: .colorTemp, value: vv)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
        
        if slider == lightSlider { //亮度
            let vv = Int(value)
            let parame = parameModel(dp: .light, value: vv)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        }
    }
}
