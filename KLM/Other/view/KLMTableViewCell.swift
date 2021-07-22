//
//  KLMTableViewCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/7.
//

import UIKit

class KLMTableViewCell: UITableViewCell, Nibloadable {
    
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var leftLab: UILabel!
    @IBOutlet weak var rightLab: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var line: UIView!
    
    @IBOutlet weak var leftImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftImageWidthConstraint: NSLayoutConstraint!
    
    var leftImage: String!{
        
        didSet {
            
            self.leftImageView.image = UIImage(named: leftImage)
        }
    }
    
    var leftTitle: String! {
        
        didSet {
            
            self.leftLab.text = leftTitle
        }
       
    }
    
    var rightTitle: String! {
        
        didSet {
            
            self.rightLab.text = rightTitle
        }
        
    }
    
    var isShowLeftImage: Bool! {
        
        didSet {
            
            if isShowLeftImage == false {
                
                self.leftImageLeadingConstraint.constant = 0;
                self.leftImageWidthConstraint.constant = 0;
            }
        }
    
    }
    
    static func cellWithTableView(tableView: UITableView) -> Self {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: String(describing: self))
        if cell == nil {
                    
            cell = Self.loadNib()
        }
        return cell as! Self
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}
