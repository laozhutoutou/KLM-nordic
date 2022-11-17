//
//  KLMControllerOperationViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/15.
//

import UIKit

class KLMControllerOperationViewController: UIViewController, Editable {
    
    @IBOutlet weak var plateView: UIView!
    /// 色卡
    @IBOutlet weak var colorItemsView: UIView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    let itemW:CGFloat = 25
    var lightValue: Int = 100
    var currentColor: UIColor = .white
    
    var isFinish = false
    
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
    
    var lightSlider: KLMSlider!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.layer.cornerRadius = 16
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finish))
        //导航栏左边添加返回按钮
        navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(dimiss)) as? [UIBarButtonItem]
        
        
        setupUI()
        
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 1) {
            self.hideEmptyView()
        }
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
                
        let viewLeft: CGFloat = 20 + 16
        let sliderWidth = KLMScreenW - viewLeft * 2
        
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 1)
        lightSlider.getValueTitle = { value in

            return String(format: "%ld%%", Int(value))
        }
        lightSlider.delegate = self
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
    }
    
    private func setupData() {
        
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
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @objc func finish() {
        
        SVProgressHUD.show()
        
        isFinish = true
        
        let string = "000003"
        let parame = parameModel(dp: .recipe, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    @objc func dimiss() {
        
        isFinish = false
        ///发送取消命名
        let string = "000002"
        let parame = parameModel(dp: .recipe, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func colorTempClick(_ sender: Any) {
        
        let vc = KLMControllerColorTempViewController()
        let nav = KLMNavigationViewController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
}

extension KLMControllerOperationViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        if message?.dp == .color, let value = message?.value as? [UInt8], message?.opCode == .read {
           
                if value.count >= 6 {
                    
                    var HH: UInt16 = 0
                    (Data(value[0...1]) as NSData).getBytes(&HH, length:2)
                    
                    var SS: UInt16 = 0
                    (Data(value[2...3]) as NSData).getBytes(&SS, length:2)
                    
                    var BB: UInt16 = 0
                    (Data(value[4...5]) as NSData).getBytes(&BB, length:2)
                    
                    
                    let H: Float = Float(HH) / 360
                    let S: Float = Float(SS) / 1000
                    let B: Float = Float(BB) / 1000
                    
                    if H == 0 && S == 0 && B == 0 { //默认白色


                    } else {

                        currentColor = UIColor.init(hue: CGFloat(H), saturation: CGFloat(S), brightness: CGFloat(B), alpha: 1)
                        self.pickView.selectionColor = currentColor
                    }
                }
                
        } else if message?.dp ==  .light, message?.opCode == .read{ //亮度
            
            let value = message?.value as! Int
            lightValue = value
            self.lightSlider.currentValue = Float(lightValue)
        }
                
        if isFinish {
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            DispatchQueue.main.asyncAfter(deadline: 0.5) {
                
                //获取根VC
                var  rootVC =  self.presentingViewController
                while  let  parent = rootVC?.presentingViewController {
                    rootVC = parent
                }
                //释放所有下级视图
                rootVC?.dismiss(animated:  true , completion:  nil )
            }
        }
        
        KLMLog("success")
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        isFinish = false
        KLMShowError(error)
    }
}

extension KLMControllerOperationViewController: KLMSliderDelegate {

    func KLMSliderWith(slider: KLMSlider, value: Float) {
            
        if slider == lightSlider { //亮度
            let vv = Int(value)
            let parame = parameModel(dp: .light, value: vv)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
}

extension KLMControllerOperationViewController: RSColorPickerViewDelegate {
    
    func colorPickerDidChangeSelection(_ colorPicker: RSColorPickerView!) {
        
    }
    
    func colorPicker(_ colorPicker: RSColorPickerView!, touchesEnded touches: Set<AnyHashable>!, with event: UIEvent!) {
                
        ///点击色盘
        self.ringSelectView.isHidden = true
        let color = colorPicker.selectionColor
        
        let parame = parameModel(dp: .color, value: color!.colorToHexString())
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

