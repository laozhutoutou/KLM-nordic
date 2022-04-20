//
//  KLMForgetPasswordViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/12/15.
//

import UIKit
import RxSwift
import RxCocoa

class KLMForgetPasswordViewController: UIViewController {
    
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    
    @IBOutlet weak var codeTextField: UITextField!
    //done
    @IBOutlet weak var doneBtn: UIButton!
    /// 验证码
    @IBOutlet weak var verCodeBtn: UIButton!
    @IBOutlet weak var eyeBtn: UIButton!
    //倒计时
    var messageTimer: Timer?
    ///当前秒
    var currentTime: Int = 60
    
    var codeTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doneBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .normal)
        doneBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor.withAlphaComponent(0.5)), for: .disabled)

        doneBtn.layer.cornerRadius = doneBtn.height / 2;
        doneBtn.clipsToBounds = true
        
        ///监控输入
        Observable.combineLatest(mailTextField.rx.text.orEmpty, passTextField.rx.text.orEmpty, codeTextField.rx.text.orEmpty) { mailText, passwordText, codeText in
            
            if mailText.isEmpty ||  passwordText.isEmpty || codeText.isEmpty{
                return false
            } else {
                return true
            }
        }.bind(to: doneBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        codeTitle = verCodeBtn.currentTitle
        
    }
    
    @IBAction func sendCode(_ sender: Any) {
        
        guard let text = mailTextField.text, text.isEmpty == false else {
            SVProgressHUD.showInfo(withStatus: mailTextField.placeholder)
            return
        }
        
        if !KLMVerifyManager.isEmail(email: text) {
            SVProgressHUD.showInfo(withStatus: LANGLOC("mailboxIncorrectTip"))
            return
        }
        
        SVProgressHUD.show()
        KLMService.getCode(email: text) { _ in
            SVProgressHUD.showSuccess(withStatus: "Verification code has been sent")
            
            ///开始倒计时
            self.startTimer()
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func done(_ sender: Any) {
        SVProgressHUD.show()
        KLMService.forgetPassword(email: mailTextField.text!, password: passTextField.text!, code: codeTextField.text!) { _ in
            
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
    
    @IBAction func eyeBtn(_ sender: UIButton) {
        passTextField.isSecureTextEntry = !passTextField.isSecureTextEntry
        var image: UIImage = #imageLiteral(resourceName: "icon_login_eyeClose")
        if !passTextField.isSecureTextEntry {
            image = #imageLiteral(resourceName: "icon_login_eyeOpen")
        }
        eyeBtn.setImage(image, for: .normal)
    }
}
