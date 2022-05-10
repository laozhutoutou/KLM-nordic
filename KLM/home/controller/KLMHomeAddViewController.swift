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
            SVProgressHUD.showInfo(withStatus: "Enter store name")
            return
        }
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        
        KLMService.addMesh(meshName: text) { response in
            ///创建一个所有设备的分组
            let meshId: Int = response as! Int
            KLMService.addGroup(meshId: meshId, groupId: 0, groupName: "所有设备") { response in
                KLMLog("分组提交成功到服务器")

                SVProgressHUD.showSuccess(withStatus: "Store successfully created")
                NotificationCenter.default.post(name: .homeAddSuccess, object: nil)
                self.navigationController?.popViewController(animated: true)

            } failure: { error in
                KLMHttpShowError(error)
            }
        
        } failure: { error in
            KLMHttpShowError(error)
        }

    }
}
