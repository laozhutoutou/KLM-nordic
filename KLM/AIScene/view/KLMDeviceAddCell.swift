//
//  KLMDeviceAddCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/11.
//

import UIKit

typealias ConnectBlock = (_ model: DiscoveredPeripheral) -> Void

class KLMDeviceAddCell: UITableViewCell, Nibloadable {
    
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var connectBtn: UIButton!
        
    var model: DiscoveredPeripheral! {
        
        didSet {
            
            self.nameLab.text = model.device.name ?? "Unknown Device"
        }
    }
    var connectBlock: ConnectBlock?
    
    static func cellWithTableView(tableView: UITableView) -> Self {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: String(describing: self))
        if cell == nil {
                    
            cell = Self.loadNib()
        }
        return cell as! Self
    }
    
    @IBAction func connectClick(_ sender: Any) {
        
        if let con = connectBlock {

            con(self.model)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        connectBtn.layer.cornerRadius = connectBtn.height / 2
        connectBtn.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}
