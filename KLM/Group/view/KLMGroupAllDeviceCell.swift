//
//  KLMGroupAllDeviceCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/3/9.
//

import UIKit
import nRFMeshProvision

class KLMGroupAllDeviceCell: KLMBaseTableViewCell {
    
    typealias SettingsBlock = () -> Void
    
    @IBOutlet weak var numLab: UILabel!
    var settingsBlock: SettingsBlock?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            
            self.numLab.text = String(format: "%d%@", notConfiguredNodes.count,LANGLOC("geDevice"))
        }
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
