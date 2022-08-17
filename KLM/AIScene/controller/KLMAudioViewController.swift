//
//  KLMAudioViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/11.
//

import UIKit

class KLMAudioViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    

    @IBAction func audioSwitch(_ sender: UISwitch) {
        
        KLMAudioManager.shared.stopPlay()
        if sender.isOn {
            
            if KLMAudioManager.shared.currentNode !=  KLMHomeManager.currentNode {
                KLMAudioManager.shared.currentNode = KLMHomeManager.currentNode
            }
            //打开语音播报
            DispatchQueue.main.asyncAfter(deadline: 1) {
                
                let parameOn = parameModel.init(dp: .audio, value: 1)
                KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: KLMHomeManager.currentNode)
            }
            
        } else { //关闭
            
            let parame = parameModel.init(dp: .audio, value: 2)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        }
    }
    
}
