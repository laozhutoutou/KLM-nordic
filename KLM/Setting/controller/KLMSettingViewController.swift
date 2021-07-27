//
//  KLMSettingViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit
import nRFMeshProvision

class KLMSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let images = [1,2,3,4]
    let titles = [[LANGLOC("language"),LANGLOC("allLightSetting")],[LANGLOC("checkUpdate"),LANGLOC("helpAdvice")]]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("More")
        self.tableView.rowHeight = 50
        
        self.tableView.backgroundColor = appBackGroupColor
    }
    
    //切换了语言更新整个APP
    func upDateUI() {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.enterMainUI()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return titles[section].count
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let title: String = titles[indexPath.section][indexPath.row]
        switch indexPath.section {
        case 0:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.leftTitle = title
            return cell
        case 1:
            
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.leftTitle = title
            return cell
        default:
            break
        }
        
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {//语言
                
                let vc = CMLanguageSettingViewController()
                vc.modalPresentationStyle = .overCurrentContext
                vc.modalTransitionStyle = .crossDissolve
                vc.langeuageBlock = {[weak self] (index: Int) in
                    guard let self = self else { return }
                    if index == 1 {
                        
                        DAConfig.userLanguage = "zh-Hans"
                        
                    }else{
                        
                        DAConfig.userLanguage = "en"
                        
                    }
                    
                    self.upDateUI()
                }
                self.tabBarController?.present(vc, animated: true, completion: nil)
                
            }else{//所有灯感应设置
                if !MeshNetworkManager.bearer.isOpen {
                    SVProgressHUD.showError(withStatus: "device offline")
                    return
                }
                
                let vc = KLMMotionViewController()
                navigationController?.pushViewController(vc, animated: true)
                
            }
        case 1:
            if indexPath.row == 0 {//检查更新
                
                let vc = KLMAPPUpdateViewController()
                navigationController?.pushViewController(vc, animated: true)
                
            }else{
                
            }
        default: break
            
        }
    }
}
