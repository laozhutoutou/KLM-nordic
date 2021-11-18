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
        
        if KLMMesh.isMeshManager(meshAdminId: homeModel.adminId!) == false {
            SVProgressHUD.showInfo(withStatus: LANGLOC("admin_permissions_tips"))
            return
        }
        
        guard let text = nameTextField.text, text.isEmpty == false else {
            SVProgressHUD.showError(withStatus: "请输入家庭名称")
            return
        }
        
        KLMService.editMesh(id: homeModel.id, meshName: text, meshConfiguration: nil) { response in
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            if let home = KLMMesh.loadHome(), self.homeModel.id == home.id {
                
                var homee = home
                homee.meshName = text
                KLMMesh.saveHome(home: homee)
                NotificationCenter.default.post(name: .homeAddSuccess, object: nil)
            }
            self.navigationController?.popViewController(animated: true)
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func deleteMesh(_ sender: Any) {
        
        if KLMMesh.isMeshManager(meshAdminId: homeModel.adminId!) == false {
            SVProgressHUD.showInfo(withStatus: LANGLOC("admin_permissions_tips"))
            return
        }
        
        KLMService.deleteMesh(id: homeModel.id) { response in
            ///删除mesh（1、mesh清除配置。2、清除家庭数据。3、刷新页面）
            if KLMMesh.loadHome()?.id == self.homeModel.id {///删除的是当前mesh
                
                KLMMesh.removeHome()
                (UIApplication.shared.delegate as! AppDelegate).createNewMeshNetwork()
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                self.navigationController?.popViewController(animated: true)
                
                NotificationCenter.default.post(name: .homeDeleteSuccess, object: nil)
                
            } else {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                self.navigationController?.popViewController(animated: true)

            }
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func addUser(_ sender: Any) {
        
        if KLMMesh.isMeshManager(meshAdminId: homeModel.adminId!) == false {
            SVProgressHUD.showInfo(withStatus: LANGLOC("admin_permissions_tips"))
            return
        }
        
        ///生成邀请码
        KLMService.getInvitationCode(meshId: self.homeModel.id) { response in
            
            guard let code = response as? String else { return }
            let alert = UIAlertController(title: "请将此邀请码提供给他人已便加入家庭,有效期3天",
                                          message: code,
                                          preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "关闭", style: .cancel)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
            
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
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if KLMMesh.isMeshManager(meshAdminId: homeModel.adminId!) == false {
            
            return false
        }
        
        let user = self.meshUsers!.data[indexPath.row]
        if user.id == homeModel.adminId {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let user = self.meshUsers!.data[indexPath.row]
        let deleteAction = UIContextualAction.init(style: .destructive, title: LANGLOC("delete")) { action, sourceView, completionHandler in
                
            let aler = UIAlertController.init(title: "删除成员", message: nil, preferredStyle: .alert)
            let cancel = UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil)
            let sure = UIAlertAction.init(title: LANGLOC("sure"), style: .default) { action in
                
                KLMService.deleteUser(meshId: self.homeModel.id, userId: user.id) { response in
                    self.getMeshUserData()
                    SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                } failure: { error in
                    KLMHttpShowError(error)
                }

            }
            aler.addAction(cancel)
            aler.addAction(sure)
            self.present(aler, animated: true, completion: nil)
            completionHandler(true)
        }
        
        let actions = UISwipeActionsConfiguration.init(actions: [deleteAction])
        return actions
    }
}
