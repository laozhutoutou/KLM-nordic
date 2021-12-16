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
        
        navigationItem.title = LANGLOC("createAStore");
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finish))
    }
    
    @objc func finish() {
        
        guard let text = nameTextField.text, text.isEmpty == false else {
            SVProgressHUD.showError(withStatus: "Enter store name")
            return
        }
        
        KLMService.addMesh(meshName: text) { response in
            SVProgressHUD.showSuccess(withStatus: "Store successfully created")
            NotificationCenter.default.post(name: .homeAddSuccess, object: nil)
            self.navigationController?.popViewController(animated: true)
            
        } failure: { error in
            KLMHttpShowError(error)
        }

    }
}
