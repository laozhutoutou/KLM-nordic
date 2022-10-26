//
//  KLMLoginPhoneViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/8.
//

import UIKit

class KLMLoginPhoneViewController: UIViewController {
    
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var logBtn: UIButton!
    @IBOutlet weak var eyeBtn: UIButton!

    @IBOutlet weak var regionLab: UILabel!
    @IBOutlet weak var countryCodeLab: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Log in via Mobile Number")
        
        logBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .normal)
        logBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor.withAlphaComponent(0.5)), for: .disabled)
        
        logBtn.layer.cornerRadius = logBtn.height / 2
        logBtn.clipsToBounds = true
    }
    
    ///选择地区
    @IBAction func tapRegion(_ sender: Any) {
        
        let vc = KLMCountryCodeViewController()
        vc.backCountryCode = { [weak self] country, code in
            guard let self = self else { return }
            
        }
        let nav = KLMNavigationViewController.init(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    @IBAction func logIn(_ sender: Any) {
        
    }
    
    @IBAction func signInEmail(_ sender: Any) {
        
        
    }
    
    @IBAction func signUp(_ sender: Any) {
        
    }
    
    @IBAction func fogotPassword(_ sender: Any) {
        
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
