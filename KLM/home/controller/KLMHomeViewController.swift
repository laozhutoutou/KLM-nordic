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
        
        tableView.backgroundColor = appBackGroupColor
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(addHome))

    }
    
    @objc func addHome() {
        
        let vc = KLMHomeAddViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func getMeshListData() {
        
        KLMService.getMeshList { response in
            
            self.homes = response as! [KLMHome.KLMHomeModel]
            self.tableView.reloadData()
            
        } failure: { error in
            KLMHttpShowError(error)
        }

    }
}

extension KLMHomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 2
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
        cell.leftTitle = LANGLOC("加入一个家庭")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            
            let home: KLMHome.KLMHomeModel = self.homes[indexPath.row]
            let vc = KLMHomeEditViewController()
            vc.homeModel = home
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        let vc = KLMJoinHomeViewController()
        navigationController?.pushViewController(vc, animated: true)
        
    }
}
