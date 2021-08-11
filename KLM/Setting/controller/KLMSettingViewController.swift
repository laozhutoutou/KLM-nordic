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
    
    let images = [["icon_language","icon_enegy_save"],["icon_app_update","icon_helpAndAdvice"]]
    let titles = [[LANGLOC("language"),LANGLOC("allDeviceAutoEnergysaving")],[LANGLOC("checkUpdate"),LANGLOC("helpAdvice")]]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("More")
        self.tableView.rowHeight = 56
        
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
        
        if indexPath.section == 0 && indexPath.row == 0 {
         
            let cell: KLMSettingSwichCell = KLMSettingSwichCell.cellWithTableView(tableView: tableView)
            return cell
        }
        let title: String = titles[indexPath.section][indexPath.row]
        let image: String = images[indexPath.section][indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.leftTitle = title
        cell.leftImage = image
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {//语言
                
                
            }else{//所有灯感应设置
                if !MeshNetworkManager.bearer.isOpen {
                    SVProgressHUD.showError(withStatus: "Device offline")
                    return
                }
                
                let vc = KLMMotionViewController()
                vc.isAllNodes = true
                navigationController?.pushViewController(vc, animated: true)
                
            }
        case 1:
            if indexPath.row == 0 {//检查更新
                
                let vc = KLMAPPUpdateViewController()
                navigationController?.pushViewController(vc, animated: true)
                
            }else{
                
                let vc = KLMHelpViewController()
                navigationController?.pushViewController(vc, animated: true)
                
            }
        default: break
            
        }
    }
}
