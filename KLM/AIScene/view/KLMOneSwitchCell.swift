//
//  KLMOneSwitchCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit

enum CameraControlType: String {
    case PASSIVE_COLOR_LIGHTING
    case MANUAL_COLOR_LIGHTING
}

class KLMOneSwitchCell: KLMBaseTableViewCell {

    
    @IBOutlet weak var cameraSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        ///查询设备信息
        var dict2 = Dictionary<String,AnyObject>()
        dict2["1"] = NSNull()
        
//        KLMHomeManager.currentNode.publishDps(dict2) {
//
//        } failure: { (error) in
//            KLMLog(error)
//        }
    }

    @IBAction func switchClick(_ sender: UISwitch) {
        
        if sender.isOn {
            
            let parame = parameModel(dp: .cameraPower, value: 1)
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode) {_ in 
                print("success")
            } failure: { error in
                KLMShowError(error)
            }

        } else {//关
            
            let parame = parameModel(dp: .cameraPower, value: 2)
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode) {_ in 
                print("success")
            } failure: { error in
                KLMShowError(error)
            }
            
        }
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}

