//
//  KLMRGBTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/6/28.
//

import UIKit

class KLMRGBTestViewController: UIViewController {
    
    @IBOutlet weak var btnsView: UIView!
    var btnArray: [UIButton] = [UIButton]()
    
    @IBOutlet weak var peifangBgView: UIView!
    var peifangSlider: KLMSlider!
    
    @IBOutlet weak var lightBgView: UIView!
    var lightSlider: KLMSlider!
    
    var currentValue: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //滑条
        let viewLeft: CGFloat = 10
        let sliderWidth = KLMScreenW - viewLeft * 2
        let RRSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: peifangBgView.height), minValue: 0, maxValue: 39, step: 1)
        RRSlider.getValueTitle = { value in
            return String(format: "%ld", Int(value))
        }
        RRSlider.currentValue = 0
        RRSlider.delegate = self
        self.peifangSlider = RRSlider
        peifangBgView.addSubview(RRSlider)
        
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 2)
        lightSlider.getValueTitle = { value in
            return String(format: "%ld%%", Int(value))
        }
        lightSlider.currentValue = 100
        lightSlider.delegate = self
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
        
        btnArray = btnsView.subviews as! [UIButton]
        
        //平均分配
        btnArray.snp.makeConstraints { make in
            make.height.equalTo(34)
            make.centerY.equalToSuperview()
        }
        btnArray.snp.distributeViewsAlong(axisType: .horizontal, fixedItemLength: 70, leadSpacing: 20, tailSpacing: 20)
        
        for btn in btnArray {
            btn.layer.cornerRadius = 3
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.gray.cgColor
            btn.clipsToBounds = true
            btn.setTitleColor(.white, for: .selected)
            btn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
            if btn.tag == currentValue {
                btn.isSelected = true
            }
        }
    }
    
    @IBAction func classificationClick(_ sender: UIButton) {
        
        if sender.tag == currentValue {
            return
        }
        currentValue = sender.tag
        for btn in btnArray {
            btn.isSelected = false
        }
        sender.isSelected = true
        
    }
    
    @IBAction func send(_ sender: Any) {
        
        //16进制字符串，2个字节，"121001"，12代表配方18，10代表亮度,00代表预览，01代表确定，02取消
        let recipeHex = Int(peifangSlider.currentValue).decimalTo2Hexadecimal()
        let lightValueHex = Int(lightSlider.currentValue).decimalTo2Hexadecimal()
        let classification = currentValue.decimalTo2Hexadecimal()
        let string = recipeHex + lightValueHex + "00" + "00" + "00" + "00" + classification
        let parame = parameModel(dp: .recipe, value: string)
        SVProgressHUD.show()
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMRGBTestViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        
    }
}

extension KLMRGBTestViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp == .recipe {
            
            SVProgressHUD.showSuccess(withStatus: "发送成功")
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
