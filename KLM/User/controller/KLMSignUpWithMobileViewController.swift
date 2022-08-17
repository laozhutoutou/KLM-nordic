//
//  KLMSignUpWithMobileViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/8.
//

import UIKit
import RxSwift
import RxCocoa

class KLMSignUpWithMobileViewController: UIViewController {
    
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    
    @IBOutlet weak var passAgainField: UITextField!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var nickNameField: UITextField!
    
    //注册
    @IBOutlet weak var signupBtn: UIButton!
    /// 验证码
    @IBOutlet weak var verCodeBtn: UIButton!
    
    @IBOutlet weak var eyeBtn: UIButton!
    @IBOutlet weak var eyaAgainBtn: UIButton!
    
    @IBOutlet weak var regionLab: UILabel!
    @IBOutlet weak var countryCodeLab: UILabel!
    
    
    //倒计时
    var messageTimer: Timer?
    ///当前秒
    var currentTime: Int = 60
    var codeTitle: String?
    
    ///数据
    var regionName: String? {
        didSet {
            regionLab.text = regionName
        }
    }
    var regionCode: String? {
        didSet{
            countryCodeLab.text = "+\(regionCode ?? "")"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Sign Up with Mobile")
        
        setupUI()
        
        events()
    }

    private func setupUI() {
        
        signupBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .normal)
        signupBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor.withAlphaComponent(0.5)), for: .disabled)
        
        signupBtn.layer.cornerRadius = signupBtn.height / 2
        signupBtn.clipsToBounds = true
        
        codeTitle = verCodeBtn.currentTitle
        
        ///监控输入
        Observable.combineLatest(phoneField.rx.text.orEmpty, passTextField.rx.text.orEmpty, codeTextField.rx.text.orEmpty,  nickNameField.rx.text.orEmpty, passAgainField.rx.text.orEmpty) { mailText, passwordText, codeText, nickNameText, passAgainText  in
            
            if mailText.isEmpty ||  passwordText.isEmpty || codeText.isEmpty || nickNameText.isEmpty || passAgainText.isEmpty {
                return false
            } else {
                return true
            }
        }.bind(to: signupBtn.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    private func events() {
        
        ///默认填充中国
        regionCode = "86"
        regionName = KLMTool.getCountryNameByPhoneCode(phoneCode: regionCode!)
    }
    
    ///获取验证码
    @IBAction func sendCode(_ sender: Any) {
        
        guard let text = KLMTool.isEmptyString(string: phoneField.text) else {
            SVProgressHUD.showInfo(withStatus: phoneField.placeholder)
            return
        }
        
        if !KLMVerifyManager.isPhone(phone: text) {
            SVProgressHUD.showInfo(withStatus: LANGLOC("The mobile number format is incorrect"))
            return
        }
        
        SVProgressHUD.show()
        KLMService.getPhoneCode(phone: text) { _ in
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Verification code has been sent"))
            
            ///开始倒计时
            self.startTimer()
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    //注册
    @IBAction func register(_ sender: Any) {
        
        //比较两次密码
        if passTextField.text != passAgainField.text {
            
            SVProgressHUD.showInfo(withStatus: LANGLOC("The password entered again is different"))
            return
        }
        
        SVProgressHUD.show()
        KLMService.signUp(telephone: phoneField.text!, password: passTextField.text!, code: codeTextField.text!, nickName: nickNameField.text!) { _ in
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            self.navigationController?.popViewController(animated: true)
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    ///选择地区
    @IBAction func tapRegion(_ sender: Any) {
        
        return
        
        let vc = KLMCountryCodeViewController()
        vc.backCountryCode = { [weak self] country, code in
            guard let self = self else { return }
            self.regionName = country
            self.regionCode = code
        }
        let nav = KLMNavigationViewController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @IBAction func signUpWithEmail(_ sender: Any) {
        
        let vc = KLMRegisterViewController()
        navigationController?.pushViewController(vc, animated: true)
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
    
    @IBAction func againEye(_ sender: Any) {
        passAgainField.isSecureTextEntry = !passAgainField.isSecureTextEntry
        var image: UIImage = #imageLiteral(resourceName: "icon_login_eyeClose")
        if !passAgainField.isSecureTextEntry {
            image = #imageLiteral(resourceName: "icon_login_eyeOpen")
        }
        eyaAgainBtn.setImage(image, for: .normal)
    }
}
