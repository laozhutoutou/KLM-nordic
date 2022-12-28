//
//  KLMSettingsViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/2/16.
//

import UIKit

class KLMSettingsViewController: UIViewController {
    
    let titles = [LANGLOC("Change Password"),LANGLOC("Log Out"),LANGLOC("Account deletion")]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Settings")
    }
}

extension KLMSettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 56
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return titles.count
        
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
            
            let alert = UIAlertController(title: LANGLOC("Log Out"),
                                          message: nil,
                                          preferredStyle: .alert)
            let resetAction = UIAlertAction(title: LANGLOC("Confirm"), style: .default) { _ in
                
                SVProgressHUD.show()
                KLMService.logout { response in
                    SVProgressHUD.dismiss()
                    ///进入登录页面
                    (UIApplication.shared.delegate as! AppDelegate).enterLoginUI()
                    
                } failure: { error in
                    KLMHttpShowError(error)
                    (UIApplication.shared.delegate as! AppDelegate).enterLoginUI()
                }
            }
            let cancelAction = UIAlertAction(title: LANGLOC("Cancel"), style: .cancel)
            alert.addAction(resetAction)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        case 2: ///注销账号
            ///账号下有mesh不能删除账号
            SVProgressHUD.show()
            KLMService.getMeshList { response in
                SVProgressHUD.dismiss()
                let homes = response as! [KLMHome.KLMHomeModel]
                if homes.count > 0  { ///有商场不能删除
                    SVProgressHUD.showInfo(withStatus: LANGLOC("Please delete or exit all stores first"))
                    return
                }
                ///弹框
                let alert = UIAlertController(title: LANGLOC("Account deletion"),
                                              message: LANGLOC("Account deletion"),
                                              preferredStyle: .alert)
                let resetAction = UIAlertAction(title: LANGLOC("Confirm"), style: .default) { _ in
                    SVProgressHUD.show()
                    let user = KLMUser.getUserInfo()!
                    KLMService.deleteAccount(userid: user.id) { response in
                        SVProgressHUD.dismiss()
                        ///进入登录页面
                        (UIApplication.shared.delegate as! AppDelegate).enterLoginUI()
                    } failure: { error in
                        KLMHttpShowError(error)
                    }

                }
                let cancelAction = UIAlertAction(title: LANGLOC("Cancel"), style: .cancel)
                alert.addAction(resetAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true)
                
            } failure: { error in
                KLMHttpShowError(error)
            }
        default: break
        }
    }
}
