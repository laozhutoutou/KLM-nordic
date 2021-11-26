//
//  KLMUserInfoCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/26.
//

import UIKit

class KLMUserInfoCell: KLMBaseTableViewCell {
    
    @IBOutlet weak var nickNameLab: UILabel!
    @IBOutlet weak var emailLab: UILabel!
    
    func setupData() {
        
        guard let user = KLMUser.getUserInfo() else { return }
        nickNameLab.text = user.nickname
        emailLab.text = user.email
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
