//
//  KLMRegisterViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/16.
//

import UIKit
import SVProgressHUD

class KLMRegisterViewController: UIViewController {
    
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    
    @IBOutlet weak var codeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func sendCode(_ sender: Any) {
        
        KLMService.getCode(email: mailTextField.text!) { _ in
            SVProgressHUD.showSuccess(withStatus: "发送成功")
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func register(_ sender: Any) {
        
        KLMService.register(email: mailTextField.text!, password: passTextField.text!, code: codeTextField.text!) { _ in
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            self.navigationController?.popViewController(animated: true)
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
}
