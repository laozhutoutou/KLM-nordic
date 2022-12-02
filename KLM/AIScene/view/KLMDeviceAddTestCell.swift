//
//  KLMDeviceAddTestCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/5/17.
//

import UIKit

class KLMDeviceAddTestCell: UITableViewCell, Nibloadable {
    
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var UUIDLab: UILabel!
    @IBOutlet weak var rssiIcon: UIImageView!
    @IBOutlet weak var iconSelect: UIButton!
    @IBOutlet weak var statusLab: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var model: DiscoveredPeripheral! {
        
        didSet {
            
            self.nameLab.text = model.device.name ?? "Unknown Device"
            UUIDLab.text = model.device.uuid.uuidString
            updateRssi(model.rssi)
        }
    }
    
    var isSel: Bool! {
        didSet {
            iconSelect.isHidden = !isSel
        }
    }
    
    var setStatus: Int = 0 {
        didSet {
            if setStatus == 1 {
                statusLab.text = "成功"
                statusLab.textColor = .green
            } else if setStatus == 2 {
                statusLab.text = "失败"
                statusLab.textColor = .red
            }
            stopActivity()
        }
    }
    
    static func cellWithTableView(tableView: UITableView) -> Self {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: String(describing: self))
        if cell == nil {
                    
            cell = Self.loadNib()
        }
        return cell as! Self
    }
    
    func updateRssi(_ rssi: Int) {
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
    
    func startActivity() {
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func stopActivity() {
        
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconSelect.isHidden = true
        activityIndicator.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
