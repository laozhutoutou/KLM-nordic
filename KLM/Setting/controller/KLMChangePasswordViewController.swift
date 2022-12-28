//
//  KLMChangePasswordViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/2/16.
//

import UIKit
import RxSwift
import RxCocoa

class KLMChangePasswordViewController: UIViewController {

    @IBOutlet weak var oldTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var passAgainField: UITextField!
    
    //done
    @IBOutlet weak var doneBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("Change Password")

        doneBtn.layer.cornerRadius = doneBtn.height / 2;
        doneBtn.backgroundColor = appMainThemeColor
        
        ///监控输入
        Observable.combineLatest(oldTextField.rx.text.orEmpty, passTextField.rx.text.orEmpty, passAgainField.rx.text.orEmpty) { oldText, passwordText, passAgainText in

            if oldText.isEmpty ||  passwordText.isEmpty || passAgainText.isEmpty{
                return false
            } else {
                return true
            }
        }.bind(to: doneBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        oldTextField.placeholder = LANGLOC("Please enter your old password")
        passTextField.placeholder = LANGLOC("Please enter a new password")
        passAgainField.placeholder = LANGLOC("Please enter the new password again")
        doneBtn.setTitle(LANGLOC("Done"), for: .normal)
        
    }
    
    @IBAction func done(_ sender: Any) {
        
        if passTextField.text != passAgainField.text {
            SVProgressHUD.showInfo(withStatus: LANGLOC("The new password entered again is different"))
            return
        }
        
        SVProgressHUD.show()
        KLMService.updatePassword(oldPassword: oldTextField.text!, newPassword: passTextField.text!) { _ in
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            self.navigationController?.popViewController(animated: true)
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
}
