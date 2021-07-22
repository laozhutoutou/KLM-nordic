//
//  CMLanguageSettingViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/7.
//

import UIKit

typealias SelectLangeuageBlock = (_ index: Int) -> Void

class CMLanguageSettingViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var CHNBtn: UIButton!
    @IBOutlet weak var ENGBtn: UIButton!
    
    var selectIndex = 0
    
    var langeuageBlock: SelectLangeuageBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.layer.cornerRadius = 5
        contentView.clipsToBounds = true
        
    }
    
    @IBAction func cancelClick(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func sureClick(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
        if selectIndex == 0 {
            
            return
        }
        
        if let langeuageB = langeuageBlock {
            langeuageB(self.selectIndex)
        }
    }
    

    @IBAction func CHNClick(_ sender: Any) {
        
        CHNBtn.isSelected = true
        ENGBtn.isSelected = false
        
        selectIndex = 1
    
    }
    
    @IBAction func ENGClick(_ sender: Any) {
        
        CHNBtn.isSelected = false
        ENGBtn.isSelected = true
        
        selectIndex = 2        
        
    }
    
}
