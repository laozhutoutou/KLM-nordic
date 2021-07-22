//
//  KLMBaseTableViewCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/11.
//

import UIKit

class KLMBaseTableViewCell: UITableViewCell, Nibloadable {
    
    static func cellWithTableView(tableView: UITableView) -> Self {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: String(describing: self))
        if cell == nil {
                    
            cell = Self.loadNib()
            
            let line = UIView()
            line.backgroundColor = UIColor.lightGray
            line.alpha = 0.4
            cell?.contentView.addSubview(line)
            line.snp.makeConstraints({ (make) in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            })
        }
        
        return cell as! Self
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
