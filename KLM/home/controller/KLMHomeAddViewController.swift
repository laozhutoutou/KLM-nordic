//
//  KLMHomeAddViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/5.
//

import UIKit
import SVProgressHUD

class KLMHomeAddViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finish))
    }
    
    @objc func finish() {
        
        guard let text = nameTextField.text, text.isEmpty == false else {
            SVProgressHUD.showError(withStatus: "请输入家庭名称")
            return
        }
        
        KLMService.addMesh(meshName: text) { response in
            
        } failure: { error in
            KLMHttpShowError(error)
        }

    }
}
