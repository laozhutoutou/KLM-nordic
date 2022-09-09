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
    ///是否是其他用户登录
    var isOtherLogin: Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        events()
    }
    
    private func setupUI() {
        
        setupData()
        
        KLMLog("login")
//        navigationItem.title = LANGLOC("Log in via Email")
        logBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .normal)
        logBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor.withAlphaComponent(0.5)), for: .disabled)
        
        logBtn.layer.cornerRadius = logBtn.height / 2
        logBtn.clipsToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .loginPageRefresh, object: nil)
        
        if apptype == .targetsGW { ///国外版没有手机号
            mailTextField.placeholder = LANGLOC("Email")
        }
    }
    
    @objc func setupData() {
        
        if let username = KLMGetUserDefault("username") {
            self.mailTextField.text = username as? String
        }

        if let password = KLMGetUserDefault("password") {
            self.passTextField.text = password as? String
        }
        
        Observable.combineLatest(mailTextField.rx.text.orEmpty, passTextField.rx.text.orEmpty) { mailText, passwordText  -> Bool in
            return mailText.count > 0 && passwordText.count > 0
        }
        .map{$0}
        .bind(to: logBtn.rx.isEnabled)
        .disposed(by: disposeBag)
        
    }
    
    private func events() {
        
        if isOtherLogin {
            isOtherLogin = false
            
            ///弹出提示框
            KLMAlertController.showAlertWithTitle(title: nil, message: LANGLOC("Your account is logged in on other devices"))
            
        }
    }

    @IBAction func login(_ sender: Any) {
                
        guard let mailText = KLMTool.isEmptyString(string: mailTextField.text) else {
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
        
        if apptype == .targetsGW {
            let register = KLMRegisterViewController()
            navigationController?.pushViewController(register, animated: true)
            return
        }
        let register = KLMSignUpWithMobileViewController()
        navigationController?.pushViewController(register, animated: true)
        
    }
    
    @IBAction func forgetPass(_ sender: Any) {
        
        if apptype == .targetsGW {
            let vc = KLMForgetPasswordViewController()
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        let vc = KLMPhoneForgotPasswordViewController()
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
