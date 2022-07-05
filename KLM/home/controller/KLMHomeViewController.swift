//
//  KLMHomeViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/5.
//

import UIKit

class KLMHomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    //数据源
    var homes: [KLMHome.KLMHomeModel] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getMeshListData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = LANGLOC("storeManagement");
        
        tableView.backgroundColor = appBackGroupColor
        
    }
    
    func getMeshListData() {
        
        SVProgressHUD.show()
        KLMService.getMeshList { response in
            SVProgressHUD.dismiss()
            self.homes = response as! [KLMHome.KLMHomeModel]
            self.tableView.reloadData()
            
        } failure: { error in
            KLMHttpShowError(error)
        }

    }
}

extension KLMHomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return homes.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 10
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.1
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        if indexPath.section == 0 {
            let home: KLMHome.KLMHomeModel = self.homes[indexPath.row]
            cell.leftTitle = home.meshName
            cell.leftLab.textColor = rgb(38, 38, 38)
            cell.line.isHidden = true
            return cell
        }
        cell.leftLab.textColor = appMainThemeColor
        cell.line.isHidden = true
        if indexPath.section == 1 {
            cell.leftTitle = LANGLOC("createAStore");
        } else {
            cell.leftTitle = LANGLOC("joinAStore");
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            let home: KLMHome.KLMHomeModel = self.homes[indexPath.row]
            let vc = KLMHomeEditViewController()
            vc.meshId = home.id
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = KLMHomeAddViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 2:
            let vc = KLMJoinHomeViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
        
    }
}
