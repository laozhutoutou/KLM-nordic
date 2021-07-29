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
    
    //长按
    @objc func longPress(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            self.delegate?.longPressItem(model: self.model)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectBtn.isHidden = true
        
        self.layer.cornerRadius = 5;
        self.clipsToBounds = true
        
        //长按
        let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(longPress(gesture:)))
        self.addGestureRecognizer(longPress)
    }
    
}
