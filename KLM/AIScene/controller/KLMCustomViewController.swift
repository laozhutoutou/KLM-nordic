//
//  KLMCustomViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/9.
//

import UIKit

struct tempColors {
    let maxTemp: Float = 4000
    let minTemp: Float = 3000
}

class KLMCustomViewController: UIViewController {

    @IBOutlet weak var plateView: UIView!
    /// 色卡
    @IBOutlet weak var colorItemsView: UIView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var colorTempBgView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    
    let itemW:CGFloat = 25
    
    var isFinish = false
    
    /// 是否已经读取
    var colorFirst = true
    var colorTempFirst = true
    var lightFirst = true
    
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
    
    /// 色盘
    lazy var pickView:  RSColorPickerView = {
        let pickView = RSColorPickerView(frame: self.plateView.bounds)
        pickView.cropToCircle = true
        pickView.showLoupe = false
        pickView.delegate = self
        return pickView
    }()
    
    var colorTempSlider: KLMSlider!
    var lightSlider: KLMSlider!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {

            setupData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("custom")
        contentView.layer.cornerRadius = 16
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finish))
        
        setupUI()
        
    }
    
    func setupUI() {
        
        view.backgroundColor = appBackGroupColor
        plateView.backgroundColor =  appBackGroupColor
        colorItemsView.backgroundColor = appBackGroupColor
        
        plateView.addSubview(pickView)
        
        colorItemsView.addSubview(self.ringSelectView)
        self.ringSelectView.isHidden = true
        self.ringSelectView.snp.makeConstraints { make in
            make.height.width.equalTo(itemW + 10)
            make.center.equalTo(0)
        }
        
        setColorItems()
        
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
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 10)
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
    
    func setColorItems() {
        
        let colorArray = [UIColor.white, UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue, rgb(255, 0, 255)]
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
        self.pickView.selectionColor = btn.backgroundColor
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
        
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                KLMLog("success")
                
            } failure: { error in
                KLMShowError(error)
            }
        }
    }
    
    @objc func finish() {
        
        isFinish = true
        
        let string = "000003"
        let parame = parameModel(dp: .recipe, value: string)
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                
                DispatchQueue.main.asyncAfter(deadline: 1) {
                    
                    //获取根VC
                    var  rootVC =  self.presentingViewController
                    while  let  parent = rootVC?.presentingViewController {
                        rootVC = parent
                    }
                    //释放所有下级视图
                    rootVC?.dismiss(animated:  true , completion:  nil )
                }
                
            } failure: { error in
                KLMShowError(error)
            }

        }
    }
    
    @objc func dimiss() {
        
        isFinish = false
        
        dismiss(animated: true, completion: nil)
    }

}

extension KLMCustomViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        if message?.dp ==  .color{
            if colorFirst {
                colorFirst = false
                let value = message?.value as! String
                let color = value.hexToColor()
                self.pickView.selectionColor = color
            }
            
            
        } else if message?.dp ==  .colorTemp{//色温
            if colorTempFirst {
                colorTempFirst = false
                let value = message?.value as! Int
                self.colorTempSlider.currentValue = Float(value)
            }
            
        } else if message?.dp ==  .light{
            if lightFirst {
                lightFirst = false
                let value = message?.value as! Int
                self.lightSlider.currentValue = Float(value)
            }
            
        }
        
        if isFinish {
            
//            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            
            //获取根VC
            var  rootVC =  self.presentingViewController
            while  let  parent = rootVC?.presentingViewController {
                rootVC = parent
            }
            //释放所有下级视图
            rootVC?.dismiss(animated:  true , completion:  nil )
        }
        
        KLMLog("success")
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        isFinish = false
        KLMShowError(error)
    }
}


extension KLMCustomViewController: KLMSliderDelegate {

    func KLMSliderWith(slider: KLMSlider, value: Float) {

        if slider == colorTempSlider {//色温
            let vv = Int(value)
            
            let parame = parameModel(dp: .colorTemp, value: vv)
            
            if KLMHomeManager.sharedInstacnce.controllType == .Device {
                
                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
                
            } else {
                
                KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                    
                    KLMLog("success")
                    
                } failure: { error in
                    KLMShowError(error)
                }
                
            }
            
        }
        
        if slider == lightSlider { //亮度
            let vv = Int(value)
            let parame = parameModel(dp: .light, value: vv)
            if KLMHomeManager.sharedInstacnce.controllType == .Device {

                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            } else {
                
                KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                    
                    KLMLog("success")
                    
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
        
        ///点击色盘
        self.ringSelectView.isHidden = true
        let color = colorPicker.selectionColor
        
        let parame = parameModel(dp: .color, value: color!.colorToHexString())
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                KLMLog("success")
                
            } failure: { error in
                KLMShowError(error)
            }
            
        }
        
        
    }
}

