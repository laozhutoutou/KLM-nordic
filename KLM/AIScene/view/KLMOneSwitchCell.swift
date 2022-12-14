//
//  KLMOneSwitchCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit

class KLMOneSwitchCell: KLMBaseTableViewCell {

    @IBOutlet weak var cameraSwitch: UISwitch!
    
    @IBOutlet weak var autoModeLab: UILabel!
    
    var cameraOnOff: Int!{
        
        didSet {
            self.cameraSwitch.isOn = cameraOnOff == 1 ? true : false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cameraSwitch.onTintColor = appMainThemeColor
        
        autoModeLab.text = LANGLOC("Auto Mode")
    }
    
    @IBAction func switchClick(_ sender: UISwitch) {
        
        SVProgressHUD.show()
        if sender.isOn {
            
            let parame = parameModel(dp: .cameraPower, value: 1)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

        } else {//关
            
            let parame = parameModel(dp: .cameraPower, value: 2)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: 1) {
            
            NotificationCenter.default.post(name: .refreshDeviceEdit, object: nil)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}

