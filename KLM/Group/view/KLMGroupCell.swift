//
//  KLMGroupCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/1/24.
//

import UIKit
import nRFMeshProvision

typealias SettingsBlock = () -> Void
class KLMGroupCell: KLMBaseTableViewCell {
    
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var numLab: UILabel!
    var settingsBlock: SettingsBlock?
    
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
        // Initialization code
    }
    
    @IBAction func settings(_ sender: Any) {
        
        if let settingsBlock = settingsBlock {
            settingsBlock()
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
