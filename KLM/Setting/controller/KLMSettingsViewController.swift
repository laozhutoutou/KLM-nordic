//
//  KLMSettingsViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/2/16.
//

import UIKit

class KLMSettingsViewController: UIViewController {
    
    let titles = [LANGLOC("ChangePassword"),LANGLOC("logout")]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("setting")
    }
}

extension KLMSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 56
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 2
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let title: String = titles[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        cell.leftTitle = title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0: ///修改密码
            
            let vc = KLMChangePasswordViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        case 1: ///退出登录
            
            let alert = UIAlertController(title: LANGLOC("logout"),
                                          message: nil,
                                          preferredStyle: .alert)
            let resetAction = UIAlertAction(title: LANGLOC("sure"), style: .destructive) { _ in
                
                SVProgressHUD.show()
                KLMService.logout { response in
                    SVProgressHUD.dismiss()
                    ///进入登录页面
                    (UIApplication.shared.delegate as! AppDelegate).enterLoginUI()
                    
                } failure: { error in
                    KLMHttpShowError(error)
                }
            }
            let cancelAction = UIAlertAction(title: LANGLOC("cancel"), style: .cancel)
            alert.addAction(resetAction)
            alert.addAction(cancelAction)
            present(alert, animated: true)
            
        default: break
            
        }
    }
}
