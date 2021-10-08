//
//  KLMGroupDeviceAddCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/8.
//

import UIKit
import nRFMeshProvision

class KLMGroupDeviceAddCell: KLMBaseTableViewCell {
    
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var iconBtn: UIButton!
    
    var isShowSelect: Bool! {

        didSet {
            iconBtn.isHidden = !isShowSelect
        }
    }
    
    var model: Node! {
        
        didSet{
            
            nameLab.text = model.nodeName
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconBtn.isHidden = true
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
