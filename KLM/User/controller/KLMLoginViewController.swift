//
//  KLMLoginViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/18.
//

import UIKit

class KLMLoginViewController: UIViewController {

    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    @IBAction func login(_ sender: Any) {
        
        KLMService.login(username: mailTextField.text!, password: passTextField.text!) { response in
            
            
        } failure: { error in
            
            KLMHttpShowError(error)
        }

    }
    
    @IBAction func register(_ sender: Any) {
        
        let register = KLMRegisterViewController()
        navigationController?.pushViewController(register, animated: true)
        
    }
    
}
