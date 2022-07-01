//
//  KLMAdminTransferViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/1.
//

import UIKit

class KLMAdminTransferViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneBtn: UIButton!
    var meshId: Int!
    var meshUsers: KLMMeshUser?
    var selectIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        
        getMeshUserData()
    }
    
    private func setUI() {
        
        navigationItem.title = LANGLOC("Administrator transfer")
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
    
    @IBAction func done(_ sender: Any) {
        
        
    }
}

extension KLMAdminTransferViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        let cell: KLMAdminTransferCell = KLMAdminTransferCell.cellWithTableView(tableView: tableView)
        cell.name = user?.nickname ?? LANGLOC("unknowUser")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }
}
