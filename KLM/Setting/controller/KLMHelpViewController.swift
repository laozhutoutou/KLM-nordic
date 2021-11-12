//
//  KLMHelpViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/9.
//

import UIKit
import SVProgressHUD

class KLMHelpViewController: UIViewController {

    @IBOutlet weak var questionView: CMTextView!
    @IBOutlet weak var phoneField: UITextField!
    
    @IBOutlet weak var commitBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("helpAdvice")

        questionView.placeholder = LANGLOC("helpQuestionTip")
        questionView.placeholderColor = rgba(0, 0, 0, 0.3)
        
        questionView.layer.cornerRadius = 6
        phoneField.layer.cornerRadius = 6
        commitBtn.layer.cornerRadius = commitBtn.height / 2
    }

    @IBAction func commit(_ sender: Any) {
        
        guard let question = self.questionView.text, question.isEmpty == false else {
            SVProgressHUD.showError(withStatus: LANGLOC("FeedBackContentEmptyTip"))
            return
        }
        
        guard let phone = self.phoneField.text, phone.isEmpty == false else {
            SVProgressHUD.showError(withStatus: LANGLOC("FeedBackContactEmptyTip"))
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
