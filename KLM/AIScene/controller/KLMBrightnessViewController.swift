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
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 1, maxValue: 100, step: 1)
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
    
    private func setupGroupData() {
        
        var address: Int = 0
        if KLMHomeManager.sharedInstacnce.controllType == .Group {
            address = Int(KLMHomeManager.currentGroup.address.address)
        }
        
        KLMService.selectGroup(groupId: address) { response in
            guard let model = response as? GroupData else { return  }
            self.groupData = model
            //UI
            self.lightValue = self.groupData.customLight
        } failure: { error in
            
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
}

extension KLMBrightnessViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .brightness, let value = message?.value as? Int {
            if message?.opCode == .read {
                lightValue = value
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
        
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {source in 
                
                self.groupData.customLight = light
                self.sendData()
                KLMLog("success")
                
            } failure: { error in
                
                KLMShowError(error)
            }
            
        } else if KLMHomeManager.sharedInstacnce.controllType == .Device {

            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in 
                
                self.groupData.customLight = light
                self.sendData()
                KLMLog("success")
                
            } failure: { error in
                KLMShowError(error)
            }
            
        }
    }
}
