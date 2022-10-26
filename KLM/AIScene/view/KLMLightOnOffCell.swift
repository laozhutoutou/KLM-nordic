//
//  KLMLightOnOffCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/18.
//

import UIKit

class KLMLightOnOffCell: KLMBaseTableViewCell {

    @IBOutlet weak var OnOffSwitch: UISwitch!
    
    var isFirst: Bool = true
    
    var onOff: Int! {
        didSet {
            self.OnOffSwitch.isOn = onOff == 1 ? true : false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        OnOffSwitch.onTintColor = appMainThemeColor
        
    }
    
    @IBAction func OnOff(_ sender: UISwitch) {
        
        if sender.isOn {
            
            if isFirst == true {
                
                let parame = parameModel(dp: .power, value: 1)
                KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
                
            } else {
                
                sender.isOn = !sender.isOn
                SVProgressHUD.showInfo(withStatus: LANGLOC("Please wait for 3 seconds"))
            }
            
        } else {//关
            
            let parame = parameModel(dp: .power, value: 0)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
            isFirst = false
            DispatchQueue.main.asyncAfter(deadline: 3) {
                self.isFirst = true
            }
            
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
