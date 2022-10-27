//
//  KLMCustomViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/9.
//

import UIKit
import JKSwiftExtension

struct tempColors {
    let maxTemp: Float = 4000
    let minTemp: Float = 3000
}

class KLMCustomViewController: UIViewController, Editable {

    @IBOutlet weak var plateView: UIView!
    /// 色卡
    @IBOutlet weak var colorItemsView: UIView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var colorTempBgView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    
    let itemW:CGFloat = 25
    
    var cameraPower: Int = 0
    var colorTempValue: Int = 6
    var lightValue: Int = 100
    var currentColor: UIColor = .white
    //是否控制
    var isTap: Bool = false
    
    var isFinish = false
        
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
    
    ///分组和所有设备使用
    var groupData: GroupData = GroupData()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {

            setupData()
        } else {
            setupGroupData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("custom")
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
    
    private func setupGroupData() {
        
        var address: Int = 0
        if KLMHomeManager.sharedInstacnce.controllType == .Group {
            address = Int(KLMHomeManager.currentGroup.address.address)
        }
        
        SVProgressHUD.show()
        KLMService.selectGroup(groupId: address) { response in
            SVProgressHUD.dismiss()
            guard let model = response as? GroupData else { return  }
            self.groupData = model
            //UI
            self.pickView.selectionColor = UIColor.init(hexString: self.groupData.customColor)
            self.colorTempSlider.currentValue = Float(self.groupData.customColorTemp)
            self.lightSlider.currentValue = Float(self.groupData.customLight)
        } failure: { error in
            SVProgressHUD.dismiss()
        }
    }
    
    private func sendData() {
        
        var address: Int = 0
        if KLMHomeManager.sharedInstacnce.controllType == .Group {
            address = Int(KLMHomeManager.currentGroup.address.address)
        }
        KLMService.updateGroup(groupId: address, groupData: self.groupData) { response in
            
        } failure: { error in
            
        }
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
        
        isTap = true
        
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
        
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {source in
                
                KLMLog("success")

            } failure: { error in
                
                KLMShowError(error)
            }
            
        } else if KLMHomeManager.sharedInstacnce.controllType == .Device {
        
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in
                
                KLMLog("success")

            } failure: { error in
                KLMShowError(error)
            }
        }
    }
    
    @objc func finish() {
        
        SVProgressHUD.show()
        
        isFinish = true
        
        let string = "000003"
        let parame = parameModel(dp: .recipe, value: string)
        
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {source in
                
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                self.groupData.colorSensing = 2
                self.groupData.customLight = Int(self.lightSlider.currentValue)
                self.groupData.customColorTemp = Int(self.colorTempSlider.currentValue)
                self.groupData.customColor = self.pickView.selectionColor.hexString!
                self.sendData()
                DispatchQueue.main.asyncAfter(deadline: 0.5) {
                    
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
            
        } else if KLMHomeManager.sharedInstacnce.controllType == .Device {
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in
                
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                self.groupData.colorSensing = 2
                self.groupData.customLight = Int(self.lightSlider.currentValue)
                self.groupData.customColorTemp = Int(self.colorTempSlider.currentValue)
                self.groupData.customColor = self.pickView.selectionColor.hexString!
                self.sendData()
                DispatchQueue.main.asyncAfter(deadline: 0.5) {
                    
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
        ///发送取消命名
        let string = "000002"
        let parame = parameModel(dp: .recipe, value: string)
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {source in
                
                
            } failure: { error in
   
            }
        } else if KLMHomeManager.sharedInstacnce.controllType == .Device {

            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

        } else {
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in

            } failure: { error in
                
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func updateUI() {
        
        if isTap == false {
            if cameraPower == 4 || cameraPower == 0 { //获取蓝牙端数据
                
                self.pickView.selectionColor = currentColor
                self.colorTempSlider.currentValue = Float(colorTempValue)
            } else { //填充默认值
                self.pickView.selectionColor = .white
                self.colorTempSlider.currentValue = 6
            }
            self.lightSlider.currentValue = Float(lightValue)
        }
    }
}

extension KLMCustomViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        if message?.dp == .color, let value = message?.value as? [UInt8] {
           
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
                    }
                }
                
        } else if message?.dp ==  .colorTemp{//色温
            
            let value = message?.value as! Int
            colorTempValue = value
            
        } else if message?.dp ==  .light{ //亮度
            
            let value = message?.value as! Int
            lightValue = value
            
        } else if message?.dp == .cameraPower {
            
            cameraPower = message?.value as! Int
        }
        
        updateUI()
        
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


extension KLMCustomViewController: KLMSliderDelegate {

    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        isTap = true

        if slider == colorTempSlider {//色温
            let vv = Int(value)
            let parame = parameModel(dp: .colorTemp, value: vv)
            if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
                
                KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {source in
                    
                    KLMLog("success")
                    
                } failure: { error in
                    
                    KLMShowError(error)
                }
                
            } else if KLMHomeManager.sharedInstacnce.controllType == .Device {
                
                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
                
            } else {
                
                KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in
                    
                    KLMLog("success")
                    
                } failure: { error in
                    KLMShowError(error)
                }
            }
        }
        
        if slider == lightSlider { //亮度
            let vv = Int(value)
            let parame = parameModel(dp: .light, value: vv)
            
            if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
                
                KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {source in
                    
                    KLMLog("success")
                    
                } failure: { error in
                    
                    KLMShowError(error)
                }
                
            } else if KLMHomeManager.sharedInstacnce.controllType == .Device {

                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            } else {
                
                KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in
                    
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
        
        isTap = true
        
        ///点击色盘
        self.ringSelectView.isHidden = true
        let color = colorPicker.selectionColor
        
        let parame = parameModel(dp: .color, value: color!.colorToHexString())
        
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {source in
                
                
            } failure: { error in
                
                KLMShowError(error)
            }
            
        } else if KLMHomeManager.sharedInstacnce.controllType == .Device {
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in

                KLMLog("success")
                
            } failure: { error in
                KLMShowError(error)
            }
            
        }
    }
}

