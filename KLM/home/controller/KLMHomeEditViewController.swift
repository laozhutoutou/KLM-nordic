//
//  KLMHomeEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/9.
//

import UIKit
import nRFMeshProvision

class KLMHomeEditViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    var homeModel: KLMHomeModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.text = homeModel.meshName
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finish))
    }
    
    @objc func finish() {
        
        guard let text = nameTextField.text, text.isEmpty == false else {
            SVProgressHUD.showError(withStatus: "请输入家庭名称")
            return
        }
        
        KLMService.editMesh(id: homeModel.id, meshName: text, meshConfiguration: nil) { response in
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func deleteMesh(_ sender: Any) {
        
//        KLMService.deleteMesh(id: homeModel.id) { response in
//
//        } failure: { error in
//            KLMHttpShowError(error)
//        }
        KLMMesh.saveHome(home: homeModel)
        
        KLMService.getMeshInfo(id: homeModel.id) { response in
            
            if let home = response as? KLMMeshInfo {
                
                ///测试导入
                let manager = MeshNetworkManager.instance
                do {
                    let data = home.data.meshConfiguration.data(using: String.Encoding.utf8)
                    _ = try manager.import(from: data!)
                    self.saveAndReload()
                    
                } catch {

                }
            }

        } failure: { error in

        }
    }
    
    func saveAndReload() {
        
        let manager = MeshNetworkManager.instance
        if manager.save() {
            
            
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
                    SVProgressHUD.showSuccess(withStatus: "Mesh Network configuration imported.")
                    
                }
                
        
        } else {
            SVProgressHUD.showError(withStatus: "Mesh configuration could not be saved.")
            
        }
    }
    
}
