//
//  KLMJoinHomeViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/12.
//

import UIKit

class KLMJoinHomeViewController: UIViewController {
    
    
    @IBOutlet weak var titleLab: UILabel!
    
    @IBOutlet weak var comfirmBtn: UIButton!
    @IBOutlet weak var invitationCodeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        comfirmBtn.layer.cornerRadius = comfirmBtn.height/2
        comfirmBtn.backgroundColor = appMainThemeColor
        
        navigationItem.title = LANGLOC("Join a store")
        
        titleLab.text = LANGLOC("Please contact with the administrator to get an invitation")
        invitationCodeTextField.placeholder = LANGLOC("Invitation code")
        comfirmBtn.setTitle(LANGLOC("Confirm"), for: .normal)
    
    }

    @IBAction func comfirm(_ sender: Any) {
        
        guard let text = KLMTool.isEmptyString(string: invitationCodeTextField.text) else {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please enter the invitation code"))
            return
        }
        
        SVProgressHUD.show()
        //转化成大写字母
        let upperText = text.uppercased()
        KLMService.joinToHome(invitationCode: upperText) { response in
            SVProgressHUD.showSuccess(withStatus: "Successfully joined in")
            NotificationCenter.default.post(name: .homeAddSuccess, object: nil)
            self.navigationController?.popViewController(animated: true)
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
}
