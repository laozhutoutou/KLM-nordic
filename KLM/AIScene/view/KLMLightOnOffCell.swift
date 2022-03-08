//
//  KLMLightOnOffCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/18.
//

import UIKit

class KLMLightOnOffCell: KLMBaseTableViewCell {

    @IBOutlet weak var OnOffSwitch: UISwitch!
    
    var onOff: Int! {
        didSet {
            self.OnOffSwitch.isOn = onOff == 1 ? true : false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func OnOff(_ sender: UISwitch) {
        
        if sender.isOn {
            
            let parame = parameModel(dp: .power, value: 1)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            

        } else {//关
            
            let parame = parameModel(dp: .power, value: 0)
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
