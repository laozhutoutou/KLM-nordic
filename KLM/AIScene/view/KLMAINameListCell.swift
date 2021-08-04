//
//  KLMAINameListCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit
import nRFMeshProvision

protocol KLMAINameListCellDelegate: AnyObject {
    
    func longPressItem(model: Node)
}

class KLMAINameListCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var selectBtn: UIButton!
    weak var delegate:  KLMAINameListCellDelegate?
    
    var isShowSelectBtn: Bool = false {
        
        didSet {
            selectBtn.isHidden = !isShowSelectBtn
        }
    }
    
    var selectBtnIsSelect: Bool = false {
        
        didSet {
            selectBtn.isSelected =  selectBtnIsSelect
        }
    }
    
    
    var model: Node! {
        
        didSet{
            
            nameLab.text = model.nodeName
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        
    }
    
    @IBAction func setClick(_ sender: Any) {
        
        self.delegate?.longPressItem(model: self.model)
    }
}
