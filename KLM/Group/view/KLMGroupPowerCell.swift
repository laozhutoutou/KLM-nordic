//
//  KLMGroupPowerCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/3/7.
//

import UIKit

class KLMGroupPowerCell: KLMBaseTableViewCell {

    @IBOutlet weak var onBtn: UIButton!
    @IBOutlet weak var offBtn: UIButton!
    
    var isAllNodes: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        onBtn.layer.cornerRadius = 4.0
        offBtn.layer.cornerRadius = 4.0
        onBtn.clipsToBounds = true
        offBtn.clipsToBounds = true
        
        onBtn.layer.borderWidth = 1
        offBtn.layer.borderWidth = 1
        
        onBtn.layer.borderColor = UIColor.lightGray.cgColor
        offBtn.layer.borderColor = UIColor.lightGray.cgColor
        
        onBtn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
        onBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        
        offBtn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
        offBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
    }
    
    @IBAction func onClick(_ sender: Any) {
        
        if onBtn.isSelected {
            return
        }
        
        onBtn.isSelected = true
        offBtn.isSelected = false
        
        let parame = parameModel(dp: .power, value: 1)
        
        if isAllNodes {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {
                KLMLog("success")
            } failure: { error in
                KLMShowError(error)
            }

        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                KLMLog("success")
                
            } failure: { error in
                KLMShowError(error)
            }
        }
        
    }
    
    @IBAction func offClick(_ sender: Any) {
        
        if offBtn.isSelected {
            return
        }
        
        onBtn.isSelected = false
        offBtn.isSelected = true
        
        let parame = parameModel(dp: .power, value: 0)
        if isAllNodes {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {
                KLMLog("success")
            } failure: { error in
                KLMShowError(error)
            }
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                KLMLog("success")
                
            } failure: { error in
                KLMShowError(error)
            }
        }
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
