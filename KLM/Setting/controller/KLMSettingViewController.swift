//
//  KLMSettingViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit
import nRFMeshProvision

private enum itemType: Int, CaseIterable {
    case userInfo = 0
    case language
    case update
    case help
    case home
    case settings
}

class KLMSettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
        
    let images = ["icon_language","icon_language","icon_app_update","icon_helpAndAdvice","icon_helpAndAdvice","icon_helpAndAdvice","icon_helpAndAdvice"]
    let titles = ["个人信息",LANGLOC("Language"),LANGLOC("App update"),LANGLOC("Help & Feedback"), LANGLOC("Store Management"),LANGLOC("Settings")]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("About")
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == itemType.userInfo.rawValue {
            return 70
        }
        if apptype == .targetSensetrack && indexPath.row == itemType.language.rawValue {
            return 0
        }
        return 56
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return itemType.allCases.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
        case itemType.userInfo.rawValue:
            let cell: KLMUserInfoCell = KLMUserInfoCell.cellWithTableView(tableView: tableView)
            cell.setupData()
            return cell
        case itemType.language.rawValue:
            let cell: KLMSettingSwichCell = KLMSettingSwichCell.cellWithTableView(tableView: tableView)
            return cell
        default:
            let title: String = titles[indexPath.row]
            let image: String = images[indexPath.row]
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.leftTitle = title
            cell.leftImage = image
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
            
        case itemType.update.rawValue://检查更新
            let vc = KLMAPPUpdateViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.help.rawValue://帮助建议
            let vc = KLMHelpViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.home.rawValue:
            let vc = KLMHomeViewController()
            navigationController?.pushViewController(vc, animated: true)
        case itemType.settings.rawValue:
            let vc = KLMSettingsViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        default: break
            
        }
    }
}
