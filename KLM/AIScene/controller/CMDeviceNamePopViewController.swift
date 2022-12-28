//
//  CMDeviceNamePopViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/11.
//

import UIKit

typealias NameBlock = (_ name: String) -> Void

class CMDeviceNamePopViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var titleNameLab: UILabel!
    
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var comfirmBtn: UIButton!
    var text: String?
    var titleName: String = ""
    
    var nameBlock: NameBlock?
    var cancelBlock: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.height))
        textField.leftView  = leftView
        textField.leftViewMode = .always
        textField.layer.cornerRadius = 4
        
        contentView.layer.cornerRadius = 8
        
        titleNameLab.text = titleName
        textField.placeholder = LANGLOC("Please enter a name")
        cancelBtn.setTitle(LANGLOC("Cancel"), for: .normal)
        comfirmBtn.setTitle(LANGLOC("Confirm"), for: .normal)
        
        textField.text = text
    }

    @IBAction func sure(_ sender: Any) {
        
        guard let text = KLMTool.isEmptyString(string: textField.text) else {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please enter a name"))
            return
        }
        
        if let nameB = nameBlock {
            nameB(text)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        if let cancel = cancelBlock {
            cancel()
        }
        
        dismiss(animated: true, completion: nil)
    }
}
