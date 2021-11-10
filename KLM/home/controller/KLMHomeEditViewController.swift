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
    
    @IBOutlet weak var tableView: UITableView!
    
    var homeModel: KLMHome.KLMHomeModel!
    var meshUsers: KLMMeshUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.text = homeModel.meshName
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finish))
        
        getMeshUserData()
    }
    
    func getMeshUserData() {
        
        KLMService.getMeshUsers(meshId: homeModel.id) { response in
            
            self.meshUsers = response as? KLMMeshUser
            self.tableView.reloadData()
            
        } failure: { error in
            
        }

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

extension KLMHomeEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.meshUsers?.data.count ?? 0
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.1
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let user = self.meshUsers?.data[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        cell.leftTitle = user?.username ?? "Unknow User"
        cell.rightTitle = user?.email
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }
}
