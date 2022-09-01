//
//  KLMAINameListCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit
import nRFMeshProvision

protocol KLMAINameListCellDelegate: AnyObject {
    
    func setItem(model: Node)
    func longPress(model: Node)
}

class KLMAINameListCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var statuImage: UIImageView!
    
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
            if model.isOnline {
                statuImage.backgroundColor = appMainThemeColor
            } else {
                statuImage.backgroundColor = .red
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        statuImage.layer.cornerRadius = statuImage.height / 2
        
        let tap = UILongPressGestureRecognizer.init(target: self, action: #selector(longPress))
        tap.minimumPressDuration = 1
        self.addGestureRecognizer(tap)
    }
    
    @IBAction func setClick(_ sender: Any) {
        
        self.delegate?.setItem(model: self.model)
    }
}

extension KLMAINameListCell {
    
    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            self.delegate?.longPress(model: self.model)
        default:
            break
        }
    }
}
