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
    
    let images = ["icon_language","icon_enegy_save","icon_app_update","icon_helpAndAdvice","icon_helpAndAdvice","icon_helpAndAdvice","icon_helpAndAdvice"]
//    let titles = [[LANGLOC("language"),LANGLOC("allDeviceAutoEnergysaving")],[LANGLOC("checkUpdate"),LANGLOC("helpAdvice"),"Export","Import"]]
    let titles = [LANGLOC("language"),LANGLOC("allDeviceAutoEnergysaving"),LANGLOC("checkUpdate"),LANGLOC("helpAdvice"), "家庭管理","退出登录"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("More")
        self.tableView.rowHeight = 56
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
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
        
        if indexPath.row == 0 {
         
            let cell: KLMSettingSwichCell = KLMSettingSwichCell.cellWithTableView(tableView: tableView)
            return cell
        }
        let title: String = titles[indexPath.row]
        let image: String = images[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.leftTitle = title
        cell.leftImage = image
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 1:
            
            if !MeshNetworkManager.bearer.isOpen {
                SVProgressHUD.showInfo(withStatus: "Connecting...")
                return
            }
            
            let vc = KLMMotionViewController()
            vc.isAllNodes = true
            navigationController?.pushViewController(vc, animated: true)
        
        case 2://检查更新
            let vc = KLMAPPUpdateViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 3://帮助建议
            let vc = KLMHelpViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 4:
            let vc = KLMHomeViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 5:
            KLMService.logout { response in
                ///进入登录页面
                (UIApplication.shared.delegate as! AppDelegate).enterLoginUI()
            } failure: { error in
                
            }

        default: break
            
        }
    }
}
