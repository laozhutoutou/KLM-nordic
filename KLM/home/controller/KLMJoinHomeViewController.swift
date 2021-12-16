//
//  KLMJoinHomeViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/12.
//

import UIKit

class KLMJoinHomeViewController: UIViewController {
    
    @IBOutlet weak var comfirmBtn: UIButton!
    @IBOutlet weak var invitationCodeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        comfirmBtn.layer.cornerRadius = comfirmBtn.height/2
        navigationItem.title = LANGLOC("joinAStore")
    
    }

    @IBAction func comfirm(_ sender: Any) {
        
        guard let text = invitationCodeTextField.text, !text.isEmpty else {
            SVProgressHUD.showError(withStatus: "Please enter the invitation code")
            return
        }
        
        KLMService.joinToHome(invitationCode: text) { response in
            SVProgressHUD.showSuccess(withStatus: "Successfully joined in")
            NotificationCenter.default.post(name: .homeAddSuccess, object: nil)
            self.navigationController?.popViewController(animated: true)
        } failure: { error in
            KLMHttpShowError(error)
        }

    }
    
}
