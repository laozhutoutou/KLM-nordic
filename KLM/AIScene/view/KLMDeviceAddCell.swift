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
    @IBOutlet weak var UUIDLab: UILabel!
    @IBOutlet weak var rssiIcon: UIImageView!
    
    var model: DiscoveredPeripheral! {
        
        didSet {
            
            self.nameLab.text = model.device.name ?? "Unknown Device"
            UUIDLab.text = model.device.uuid.uuidString
            updateRssi(model.rssi)
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
        
        if model.rssi <= -90 {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Bluetooth signal is too weak"))
            return
        }
        
        if let con = connectBlock {

            con(self.model)
        }
    }
    
    private func updateRssi(_ rssi: Int) {
        switch rssi {
        case -128:
            rssiIcon.image = nil
        case -127 ..< -80:
            rssiIcon.image = #imageLiteral(resourceName: "rssi_1")
        case -80 ..< -60:
            rssiIcon.image = #imageLiteral(resourceName: "rssi_2")
        case -60 ..< -40:
            rssiIcon.image = #imageLiteral(resourceName: "rssi_3")
        default:
            rssiIcon.image = #imageLiteral(resourceName: "rssi_4")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
