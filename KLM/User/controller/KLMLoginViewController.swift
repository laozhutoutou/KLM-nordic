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
    
    @IBOutlet weak var logBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logBtn.layer.cornerRadius = logBtn.height / 2;

        if let username = KLMGetUserDefault("username") {
            mailTextField.text = username as? String
        }
        
        if let password = KLMGetUserDefault("password") {
            passTextField.text = password as? String
        }
    }

    @IBAction func login(_ sender: Any) {
        
        KLMService.login(username: mailTextField.text!, password: passTextField.text!) { _ in
            
            ///进入主页面
            let appdelegate = UIApplication.shared.delegate as! AppDelegate
            appdelegate.enterMainUI()
            
        } failure: { error in
            
            KLMHttpShowError(error)
        }

    }
    
    @IBAction func register(_ sender: Any) {
        
        let register = KLMRegisterViewController()
        navigationController?.pushViewController(register, animated: true)
        
    }
    
    @IBAction func forgetPass(_ sender: Any) {
        
        let vc = KLMForgetPasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
