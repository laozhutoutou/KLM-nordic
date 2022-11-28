//
//  KLMAudioViewTestController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/11.
//

import UIKit

class KLMAudioViewTestController: UIViewController {
    
    @IBOutlet weak var audioSwitch: UISwitch!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        KLMTestAudioManager.shared.currentNode = KLMHomeManager.currentNode
        
        audioSwitch.onTintColor = appMainThemeColor
        
        navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(dimiss)) as? [UIBarButtonItem]
    }
    
    @objc func dimiss() {
        
        ///发送语音关闭指令
        KLMAudioManager.shared.stopPlay()

        ///关闭语音播报
        let parame = parameModel.init(dp: .audio, value: 2)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
        dismiss(animated: true)
    }
    
    private func setupData() {
        
        let parame = parameModel(dp: .audio)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func audioSwitch(_ sender: UISwitch) {
        
        if sender.isOn {
        
            //打开语音播报
            DispatchQueue.main.asyncAfter(deadline: 1) {
                
                let parameOn = parameModel.init(dp: .audio, value: 1)
                KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: KLMHomeManager.currentNode)
            }
            
        } else { //关闭
            
            KLMTestAudioManager.shared.stopPlay()
            
            let parame = parameModel.init(dp: .audio, value: 2)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        }
    }
}

extension KLMAudioViewTestController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .audio, let value = message?.value as? [UInt8] {
            if message?.opCode == .read {
                
                if value.count >= 2 { ///设备端主动下发语音指令
                    
                    let secondIndex = Int(value[1])
                    KLMTestAudioManager.shared.startPlay(type: secondIndex)
                    
                } else { //获取到开关状态
                    
                    let firstIndex = Int(value[0])
                    audioSwitch.isOn = firstIndex == 1 ? true : false
                }
            }
        }
    }
        
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
