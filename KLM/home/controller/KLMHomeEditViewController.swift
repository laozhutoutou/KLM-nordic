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
    @IBOutlet weak var deleteBtn: UIButton!
    
    var meshInfo: KLMMeshInfo.KLMMeshInfoData?
    var meshId: Int!
    var meshUsers: KLMMeshUser?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getMeshInfo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("storeSettings")
        deleteBtn.layer.cornerRadius = deleteBtn.height / 2
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finish))
        
        getMeshUserData()
        
        getMeshInfo()
    }
    
    private func getMeshUserData() {
        
        SVProgressHUD.show()
        KLMService.getMeshUsers(meshId: meshId) { response in
            SVProgressHUD.dismiss()
            self.meshUsers = response as? KLMMeshUser
            self.tableView.reloadData()
            
        } failure: { error in
            KLMHttpShowError(error)
        }

    }
    
    private func getMeshInfo() {
        
        SVProgressHUD.show()
        KLMService.getMeshInfo(id: meshId) { response in
            SVProgressHUD.dismiss()
            self.meshInfo = response as? KLMMeshInfo.KLMMeshInfoData
            self.nameTextField.text = self.meshInfo?.meshName
            self.tableView.reloadData()
        } failure: { error in
            
            KLMHttpShowError(error)
        }
    }
    
    @objc func finish() {
        
        guard let meshIn = meshInfo else { return  }
        if KLMMesh.isMeshManager(meshAdminId: meshIn.adminId) == false {
            SVProgressHUD.showInfo(withStatus: LANGLOC("admin_permissions_tips"))
            return
        }
        
        guard let text = KLMTool.isEmptyString(string: nameTextField.text) else {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please enter store name"))
            return
        }
        
        SVProgressHUD.show()
        KLMService.editMesh(id: meshId, meshName: text, meshConfiguration: nil) { response in
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            if let home = KLMMesh.loadHome(), self.meshId == home.id {
                
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
        
        guard let meshIn = meshInfo else { return  }
        if KLMMesh.isMeshManager(meshAdminId: meshIn.adminId) == false {
            SVProgressHUD.showInfo(withStatus: LANGLOC("admin_permissions_tips"))
            return
        }
        
        //有灯不给删
        let meshnetwork = KLMMesh.getMeshNetwork(meshConfiguration: meshIn.meshConfiguration)
        let notConfiguredNodes = meshnetwork.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
        if notConfiguredNodes.count > 0 { //有设备不给删除
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please remove or reset all lights from the store"))
            return
        }
        
        let aler = UIAlertController.init(title: LANGLOC("deleteStore"), message: LANGLOC("deleteStoreTip"), preferredStyle: .alert)
        let cancel = UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil)
        let sure = UIAlertAction.init(title: LANGLOC("sure"), style: .default) { action in
            
            SVProgressHUD.show()
            KLMService.deleteMesh(id: self.meshId) { response in
                ///删除mesh（1、mesh清除配置。2、清除家庭数据。3、刷新页面）
                if KLMMesh.loadHome()?.id == self.meshId {///删除的是当前mesh
                    
                    KLMMesh.deleteHome()
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
        aler.addAction(cancel)
        aler.addAction(sure)
        self.present(aler, animated: true, completion: nil)
    }
    
    private func addMember() {
        
        guard let meshIn = meshInfo else { return  }
        if KLMMesh.isMeshManager(meshAdminId: meshIn.adminId) == false {
            SVProgressHUD.showInfo(withStatus: LANGLOC("admin_permissions_tips"))
            return
        }
        
        SVProgressHUD.show()
        ///生成邀请码
        KLMService.getInvitationCode(meshId: meshId) { response in
            
            SVProgressHUD.dismiss()
            
            guard let code = response as? String else { return }
            let alert = UIAlertController(title: LANGLOC("invitationCodetip"),
                                          message: code,
                                          preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: LANGLOC("close"), style: .cancel)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
}

extension KLMHomeEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 1 || section == 2 {
            return 1
        }
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
        
        if indexPath.section == 1 {
            
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("AddMember")
            cell.leftLab.textColor = appMainThemeColor
            cell.rightTitle = ""
            return cell
        }
        
        if indexPath.section == 2 {
            
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Administrator transfer")
            cell.leftLab.textColor = appMainThemeColor
            cell.rightTitle = ""
            return cell
        }
        
        let user = self.meshUsers?.data[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        cell.leftLab.textColor = rgb(38, 38, 38)
        if let meshIn = meshInfo, user?.id == meshIn.adminId{
            cell.leftTitle = LANGLOC("Administrator")
        } else {
            cell.leftTitle = user?.nickname ?? LANGLOC("unknowUser")
        }
        cell.rightTitle = user?.username
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 { //添加成员
            
            addMember()
        }
        
        if indexPath.section == 2 { //转移管理员
            
            guard let meshIn = meshInfo else { return  }
            if KLMMesh.isMeshManager(meshAdminId: meshIn.adminId) == false {
                SVProgressHUD.showInfo(withStatus: LANGLOC("admin_permissions_tips"))
                return
            }
            
            let vc = KLMAdminTransferViewController()
            vc.meshId = meshId
            vc.adminId = meshIn.adminId
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if indexPath.section == 1 || indexPath.section == 2 {
            return false
        }
        
        
        if let meshIn = meshInfo, KLMMesh.isMeshManager(meshAdminId: meshIn.adminId) == false {

            return false
        }

        let user = self.meshUsers!.data[indexPath.row]
        if let meshIn = meshInfo, user.id == meshIn.adminId {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let user = self.meshUsers!.data[indexPath.row]
        let deleteAction = UIContextualAction.init(style: .destructive, title: LANGLOC("delete")) { action, sourceView, completionHandler in
                
            let aler = UIAlertController.init(title: LANGLOC("deleteMember"), message: nil, preferredStyle: .alert)
            let cancel = UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil)
            let sure = UIAlertAction.init(title: LANGLOC("sure"), style: .default) { action in
                
                SVProgressHUD.show()
                KLMService.deleteUser(meshId: self.meshId, userId: user.id) { response in
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
