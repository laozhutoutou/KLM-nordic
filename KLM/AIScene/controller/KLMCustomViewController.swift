//
//  KLMCustomViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/9.
//

import UIKit

struct tempColors {
    let maxTemp: Float = 7000
    let minTemp: Float = 2000
}

class KLMCustomViewController: UIViewController {
    
    
    @IBOutlet weak var plateView: UIView!
    @IBOutlet weak var colorItemsView: UIView!
    @IBOutlet weak var colorTempBgView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    
    let itemW:CGFloat = 25
    
    var isFirstTimeColor = true
    var isFirstTimeTemp = true
    var isFirstTimeLight = true
    
    //模态视图跳转
    var isModel: Bool = false {
        
        didSet {
            
            if isModel {
                //导航栏左边添加返回按钮
                self.navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(dimiss)) as? [UIBarButtonItem]
            }
            
        }
    }
    
    let colorTemp = tempColors()
    
    lazy var ringSelectView: UIView = {
        let ring = UIView.init()
        ring.layer.borderWidth = 1.5
        ring.layer.cornerRadius =  (itemW + 10) / 2
        ring.clipsToBounds = true
        return ring
    }()
    
    lazy var pickView:  RSColorPickerView = {
        let pickView = RSColorPickerView(frame: self.plateView.bounds)
        pickView.cropToCircle = true
        pickView.showLoupe = false
        pickView.delegate = self
        return pickView
    }()
    
    var colorTempSlider: KLMSlider!
    var lightSlider: KLMSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        plateView.addSubview(pickView)
        
        colorItemsView.addSubview(self.ringSelectView)
        self.ringSelectView.isHidden = true
        self.ringSelectView.snp.makeConstraints { make in
            make.height.width.equalTo(itemW + 10)
            make.center.equalTo(0)
        }
        
        setColorItems()
        
        ///色温滑条
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
    
        let colorTempSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: colorTempBgView.height), minValue: 0, maxValue: 100, step: 10)
        colorTempSlider.indicateViewWidth = 42
        colorTempSlider.getValueTitle = {  value in
            
            let vv = value / 100.0 * (self.colorTemp.maxTemp - self.colorTemp.minTemp) + self.colorTemp.minTemp
            return String(format: "%ldK", Int(vv))
        }
        colorTempSlider.delegate = self
        self.colorTempSlider = colorTempSlider
        colorTempBgView.addSubview(colorTempSlider)
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 10)
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
//        var dict2 = Dictionary<String,AnyObject>()
//        dict2["1"] = NSNull()
//
//        KLMHomeManager.currentNode.publishDps(dict2) {
//
//        } failure: { (error) in
//            KLMLog(error)
//        }
    }
    
    func setColorItems() {
        
        let colorArray = [UIColor.white, UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue, UIColor.purple]
        var btnArray = [UIButton]()
        for (i, color) in colorArray.enumerated() {
            
            let btn = UIButton.init()
            btn.layer.cornerRadius = itemW / 2
            btn.clipsToBounds = true
            if i == 0 {
                btn.layer.borderWidth = 1
                btn.layer.borderColor = UIColor.lightGray.cgColor
            }
            btn.backgroundColor = color
            btn.addTarget(self, action: #selector(tapColorBtn(btn:)), for: .touchUpInside)
            btnArray.append(btn)
            colorItemsView.addSubview(btn)
        }
        
        btnArray.snp.makeConstraints { (make) in
            make.height.equalTo(itemW)
            make.centerY.equalToSuperview()
        }
        
        btnArray.snp.distributeViewsAlong(axisType: .horizontal, fixedItemLength: itemW, leadSpacing: 0, tailSpacing: 0)
    }
    
    @objc func tapColorBtn(btn: UIButton) {
        
        self.ringSelectView.isHidden = false
        if btn.backgroundColor == UIColor.white {
            
            self.ringSelectView.layer.borderColor = btn.layer.borderColor
            
        } else {
            
            self.ringSelectView.layer.borderColor = btn.backgroundColor?.cgColor
        }
        
        self.ringSelectView.snp.updateConstraints { make in
            make.center.equalTo(btn.center)
        }
        
        let color = btn.backgroundColor
        
        let parame = parameModel(dp: .color, value: color!.colorToHexString())
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {
        
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode) {_ in 
                print("success")
            } failure: { error in
                KLMShowError(error)
            }

            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                print("success")
                
            } failure: { error in
                KLMShowError(error)
            }
            
        }
    
    }
    
    @objc func dimiss() {
        
        dismiss(animated: true, completion: nil)
    }

}

extension KLMCustomViewController: KLMSliderDelegate {

    func KLMSliderWith(slider: KLMSlider, value: Float) {

        if slider == colorTempSlider {//色温
            let vv = Int(value)
            
            let parame = parameModel(dp: .colorTemp, value: vv)
            
            if KLMHomeManager.sharedInstacnce.controllType == .Device {
                
                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode) {_ in 
                    print("success")
                } failure: { error in
                    KLMShowError(error)
                }
                
            } else {
                
                KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                    
                    print("success")
                    
                } failure: { error in
                    KLMShowError(error)
                }
                
            }
            
        }
        
        if slider == lightSlider { //亮度
            let vv = Int(value * 1000)
            let parame = parameModel(dp: .light, value: vv)
            if KLMHomeManager.sharedInstacnce.controllType == .Device {

                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode) {_ in 
                    print("success")
                } failure: { error in
                    KLMShowError(error)
                }
            } else {
                
                KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                    
                    print("success")
                    
                } failure: { error in
                    KLMShowError(error)
                }
                
            }
            
        }
    }
}

extension KLMCustomViewController: RSColorPickerViewDelegate {
    
    func colorPickerDidChangeSelection(_ colorPicker: RSColorPickerView!) {
        
    }
    
    func colorPicker(_ colorPicker: RSColorPickerView!, touchesEnded touches: Set<AnyHashable>!, with event: UIEvent!) {
        
        let color = colorPicker.selectionColor
        
        let parame = parameModel(dp: .color, value: color!.colorToHexString())
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode) {_ in 
                print("success")
            } failure: { error in
                KLMShowError(error)
            }
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                print("success")
                
            } failure: { error in
                KLMShowError(error)
            }
            
        }
        
        
    }
}

