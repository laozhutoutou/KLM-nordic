//
//  KLMSettingSwichCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit

class KLMSettingSwichCell: KLMBaseTableViewCell {

    @IBOutlet weak var CNBtn: UIButton!
    @IBOutlet weak var ENBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if Bundle.isChineseLanguage() {
            CNBtn.isSelected = true
        }
        if Bundle.isEnglishLanguage() {
            ENBtn.isSelected = true
        }
    }
    
    @IBAction func CNClick(_ sender: Any) {
        if CNBtn.isSelected {
            return
        }
        CNBtn.isSelected = true
        ENBtn.isSelected = false
        DAConfig.userLanguage = "zh-Hans"
        upDateUI()
    }
    
    @IBAction func ENClick(_ sender: Any) {
        if ENBtn.isSelected {
            return
        }
        CNBtn.isSelected = false
        ENBtn.isSelected = true
        DAConfig.userLanguage = "en"
        upDateUI()
    }
    
    func upDateUI() {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.enterMoreUI()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
