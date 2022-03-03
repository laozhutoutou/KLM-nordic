//
//  KLMRegisterViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/16.
//

import UIKit
import SVProgressHUD
import RxSwift
import RxCocoa

class KLMRegisterViewController: UIViewController {
    
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var nickNameField: UITextField!
    
    //注册
    @IBOutlet weak var signupBtn: UIButton!
    /// 验证码
    @IBOutlet weak var verCodeBtn: UIButton!
    //倒计时
    var messageTimer: Timer?
    ///当前秒
    var currentTime: Int = 60
    
    var codeTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        signupBtn.layer.cornerRadius = signupBtn.height / 2;
        
        ///监控输入
        Observable.combineLatest(mailTextField.rx.text.orEmpty, passTextField.rx.text.orEmpty, codeTextField.rx.text.orEmpty,  nickNameField.rx.text.orEmpty) { mailText, passwordText, codeText, nickNameText in
            
            if mailText.isEmpty ||  passwordText.isEmpty || codeText.isEmpty || nickNameText.isEmpty {
                return false
            } else {
                return true
            }
        }.bind(to: signupBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        codeTitle = verCodeBtn.currentTitle
        
    }
    ///获取验证码
    @IBAction func sendCode(_ sender: Any) {
        
        guard let text = mailTextField.text, text.isEmpty == false else {
            SVProgressHUD.showInfo(withStatus: mailTextField.placeholder)
            return
        }
        SVProgressHUD.show()
        KLMService.getCode(email: mailTextField.text!) { _ in
            SVProgressHUD.showSuccess(withStatus: "Verification code has been sent")
            
            ///开始倒计时
            self.startTimer()
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func register(_ sender: Any) {
        
        SVProgressHUD.show()
        KLMService.register(email: mailTextField.text!, password: passTextField.text!, code: codeTextField.text!, nickName: nickNameField.text!) { _ in
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            self.navigationController?.popViewController(animated: true)
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    private func startTimer() {
        
        stopTime()
        
        verCodeBtn.isEnabled = false
        messageTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(UpdateTimer), userInfo: nil, repeats: true)
    }
    
    private func stopTime() {
        currentTime = 60
        if messageTimer != nil {
            messageTimer?.invalidate()
            messageTimer = nil
        }
    }
    
    @objc func UpdateTimer() {
        
        currentTime -= 1
        verCodeBtn.setTitle("\(currentTime)s", for: .normal)
        if currentTime <= 0 {//结束
            stopTime()
            verCodeBtn.isEnabled = true
            verCodeBtn.setTitle(codeTitle, for: .normal)
        }
    }
}
