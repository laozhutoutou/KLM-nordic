//
//  KLMHelpViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/9.
//

import UIKit

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
        
        
    }
}
