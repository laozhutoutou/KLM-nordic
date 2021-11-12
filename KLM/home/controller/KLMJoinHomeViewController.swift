//
//  KLMJoinHomeViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/12.
//

import UIKit

class KLMJoinHomeViewController: UIViewController {
    
    @IBOutlet weak var invitationCodeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    
    }

    @IBAction func comfirm(_ sender: Any) {
        
        guard let text = invitationCodeTextField.text, !text.isEmpty else {
            SVProgressHUD.showError(withStatus: "请输入邀请码")
            return
        }
        
        
    }
    
}
