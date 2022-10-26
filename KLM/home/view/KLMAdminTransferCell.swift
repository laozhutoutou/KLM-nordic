//
//  KLMAdminTransferCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/1.
//

import UIKit

class KLMAdminTransferCell: KLMBaseTableViewCell {
    
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var iconBtn: UIButton!
    
    var isShowSelect: Bool! {

        didSet {
            iconBtn.isHidden = !isShowSelect
        }
    }
    
    var name: String! {
        
        didSet{
            
            nameLab.text = name
            
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
