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
    
    var text: String?
    var titleName: String = ""
    
    var nameBlock: NameBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.height))
        textField.leftView  = leftView
        textField.leftViewMode = .always
        textField.layer.cornerRadius = 4
        
        contentView.layer.cornerRadius = 8
        
        titleNameLab.text = titleName
        textField.text = text
    }

    @IBAction func sure(_ sender: Any) {
        
        guard let text = self.textField.text,text.isEmpty == false else {
            
            return
            
        }
        
        if let nameB = nameBlock {
            nameB(text)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
}
