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
            KLMHttpShowError(error)
        }

    }
    
    @objc func finish() {
        
        guard let text = nameTextField.text, text.isEmpty == false else {
            SVProgressHUD.showError(withStatus: "请输入家庭名称")
            return
        }
        
        KLMService.editMesh(id: homeModel.id, meshName: text, meshConfiguration: nil) { response in
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            self.navigationController?.popViewController(animated: true)
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func deleteMesh(_ sender: Any) {
        
        KLMService.deleteMesh(id: homeModel.id) { response in
            ///删除mesh（1、mesh清除配置。2、清除家庭数据。3、刷新页面）
            if KLMMesh.currentHome?.id == self.homeModel.id {///删除的是当前mesh
                
                KLMMesh.removeHome()
                (UIApplication.shared.delegate as! AppDelegate).createNewMeshNetwork()
                (UIApplication.shared.delegate as! AppDelegate).enterMainUI()
                
            } else {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                self.navigationController?.popViewController(animated: true)

            }
        } failure: { error in
            KLMHttpShowError(error)
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
