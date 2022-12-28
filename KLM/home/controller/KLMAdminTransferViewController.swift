//
//  KLMAdminTransferViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/1.
//

import UIKit
import RxSwift
import RxCocoa

class KLMAdminTransferViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneBtn: UIButton!
    
    var meshId: Int!
    var adminId: Int!///管理员ID
    var meshUsers: [KLMMeshUser.KLMMeshUserData]?
    @objc dynamic private var selectIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        
        getMeshUserData()
    }
    
    private func setUI() {
        
        navigationItem.title = LANGLOC("Administrator transfer")
        doneBtn.layer.cornerRadius = doneBtn.height / 2
        doneBtn.backgroundColor = appMainThemeColor
        
        ///监控输入
        self.rx.observeWeakly(Int.self, "selectIndex")
            .subscribe(onNext: { index in
                self.doneBtn.isEnabled = index! >= 0
            })
            .disposed(by: disposeBag)
        
        doneBtn.setTitle(LANGLOC("Done"), for: .normal)
    }
    
    private func getMeshUserData() {
        
        SVProgressHUD.show()
        KLMService.getMeshUsers(meshId: meshId) { response in
            SVProgressHUD.dismiss()
            let meshUser = response as? KLMMeshUser
            self.meshUsers = meshUser?.data.filter({$0.id != self.adminId})
            self.tableView.reloadData()
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    @IBAction func done(_ sender: Any) {
        
        let aler = UIAlertController.init(title: LANGLOC("Administrator transfer"), message: LANGLOC("You will not have administrative access rights for the store"), preferredStyle: .alert)
        let cancel = UIAlertAction.init(title: LANGLOC("Cancel"), style: .cancel, handler: nil)
        let sure = UIAlertAction.init(title: LANGLOC("Confirm"), style: .default) { action in
            
            SVProgressHUD.show()
            let user = self.meshUsers![self.selectIndex]
            let loginUser = KLMUser.getUserInfo()!
            KLMService.transferAdmin(meshId: self.meshId, fromId: loginUser.id, to: user.id) { response in
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Successful transfer"))
                
                if var loadHome = KLMMesh.loadHome(),  loadHome.id == self.meshId {///转移的是当前mesh
                    
                    loadHome.adminId = user.id
                    KLMMesh.saveHome(home: loadHome)
                    
                }
                DispatchQueue.main.asyncAfter(deadline: 0.5) {
                    self.navigationController?.popViewController(animated: true)
                }
            } failure: { error in
                KLMHttpShowError(error)
            }

        }
        aler.addAction(cancel)
        aler.addAction(sure)
        present(aler, animated: true, completion: nil)

    }
}

extension KLMAdminTransferViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        return meshUsers?.count ?? 0
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
        
        let user = meshUsers?[indexPath.row]
        let cell: KLMAdminTransferCell = KLMAdminTransferCell.cellWithTableView(tableView: tableView)
        cell.name = user?.nickname ?? LANGLOC("Unknow user")
        cell.isShowSelect = indexPath.row == selectIndex
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectIndex = indexPath.row
        tableView.reloadData()
    }
}
