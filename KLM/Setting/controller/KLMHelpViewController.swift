//
//  KLMHelpViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/9.
//  这是测试合并

import UIKit
import SVProgressHUD

class KLMHelpViewController: UIViewController {

    @IBOutlet weak var questionView: CMTextView!
    @IBOutlet weak var phoneField: UITextField!
    
    @IBOutlet weak var commitBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("helpAdvice")

        questionView.placeholderTitle = LANGLOC("helpQuestionTip")
        questionView.placeholderColor = rgba(0, 0, 0, 0.3)
        
        questionView.layer.cornerRadius = 6
        phoneField.layer.cornerRadius = 6
        commitBtn.layer.cornerRadius = commitBtn.height / 2
        commitBtn.backgroundColor = appMainThemeColor
    }

    @IBAction func commit(_ sender: Any) {
        
        guard let question = KLMTool.isEmptyString(string: questionView.text) else {
            SVProgressHUD.showInfo(withStatus: LANGLOC("FeedBackContentEmptyTip"))
            return
        }
        
        guard let phone = KLMTool.isEmptyString(string: phoneField.text) else {
            SVProgressHUD.showInfo(withStatus: LANGLOC("FeedBackContactEmptyTip"))
            return
        }
        
        ///不是手机同时不是邮箱
        if !KLMVerifyManager.isPhone(phone: phone) && !KLMVerifyManager.isEmail(email: phone) {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Invalid contact"))
            return
        }
        
        
        SVProgressHUD.show()
        KLMService.feedBack(contacts: phone, content: question) { response in
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            DispatchQueue.main.asyncAfter(deadline: 0.5) {
                self.navigationController?.popViewController(animated: true)
            }
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
}
