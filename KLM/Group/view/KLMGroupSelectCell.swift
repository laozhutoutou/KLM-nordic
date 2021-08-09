//
//  KLMGroupSelectCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit
import RxCocoa
import RxSwift
import nRFMeshProvision

class KLMGroupSelectCell: KLMBaseTableViewCell {
    
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var numLab: UILabel!
    @IBOutlet weak var iconBtn: UIButton!
    
    var isShowSelect: Bool! {

        didSet {
            iconBtn.isHidden = !isShowSelect
        }
    }
    
    var model: Group! {
        
        didSet {
            self.nameLab.text = model.name
            if let network = MeshNetworkManager.instance.meshNetwork {
                
                let models = network.models(subscribedTo: model)
                self.numLab.text = String(format: "%d%@", models.count,LANGLOC("geDevice"))
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconBtn.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
