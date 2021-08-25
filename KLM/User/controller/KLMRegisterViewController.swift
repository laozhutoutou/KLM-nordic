//
//  KLMRegisterViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/16.
//

import UIKit

class KLMRegisterViewController: UIViewController {
    
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    
    @IBOutlet weak var codeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBAction func sendCode(_ sender: Any) {
        
        KLMService.getCode(email: mailTextField.text!) { _ in
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func register(_ sender: Any) {
        
        KLMService.register(email: mailTextField.text!, password: passTextField.text!, code: codeTextField.text!) { _ in
            
            SVProgressHUD.showSuccess(withStatus: "success")
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
}
