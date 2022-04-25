//
//  KLMLoginViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/18.
//

import UIKit
import SVProgressHUD
import SwiftUI
import RxSwift
import RxCocoa

class KLMLoginViewController: UIViewController {

    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    
    @IBOutlet weak var logBtn: UIButton!
    
    @IBOutlet weak var eyeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .normal)
        logBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor.withAlphaComponent(0.5)), for: .disabled)
        
        logBtn.layer.cornerRadius = logBtn.height / 2
        logBtn.clipsToBounds = true
        
        if let username = KLMGetUserDefault("username") {
            mailTextField.text = username as? String
        }

        if let password = KLMGetUserDefault("password") {
            passTextField.text = password as? String
        }
        
        ///监控输入
        Observable.combineLatest(mailTextField.rx.text.orEmpty, passTextField.rx.text.orEmpty) { mailText, passwordText  -> Bool in
            return mailText.count > 0 && passwordText.count > 0
        }
        .map{$0}
        .bind(to: logBtn.rx.isEnabled)
        .disposed(by: disposeBag)
    }

    @IBAction func login(_ sender: Any) {
        
        guard let mailText = mailTextField.text, mailText.isEmpty == false else {
            SVProgressHUD.showInfo(withStatus: mailTextField.placeholder)
            return
        }
        
//        if !KLMVerifyManager.isEmail(email: mailText) {
//            SVProgressHUD.showInfo(withStatus: LANGLOC("mailboxIncorrectTip"))
//            return
//        }
        
        SVProgressHUD.show()
        KLMService.login(username: mailText, password: passTextField.text!) { _ in
            SVProgressHUD.dismiss()
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
    
    @IBAction func eyeBtn(_ sender: UIButton) {
        passTextField.isSecureTextEntry = !passTextField.isSecureTextEntry
        var image: UIImage = #imageLiteral(resourceName: "icon_login_eyeClose")
        if !passTextField.isSecureTextEntry {
            image = #imageLiteral(resourceName: "icon_login_eyeOpen")
        }
        eyeBtn.setImage(image, for: .normal)
    }
    
}
