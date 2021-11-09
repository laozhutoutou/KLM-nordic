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
    var homes: [KLMHomeModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(addHome))
        
        getMeshListData()
    }
    
    @objc func addHome() {
        
        let vc = KLMHomeAddViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func getMeshListData() {
        
        KLMService.getMeshList { response in
            
            if let home = response as? KLMHome {
                
                self.homes = home.data.admin + home.data.participant
                self.tableView.reloadData()
            }
            
            
        } failure: { error in
            KLMHttpShowError(error)
        }

    }
}

extension KLMHomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return homes.count
        
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
        
        let home: KLMHomeModel = self.homes[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        cell.leftTitle = home.meshName
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let home: KLMHomeModel = self.homes[indexPath.row]
        let vc = KLMHomeEditViewController()
        vc.homeModel = home
        navigationController?.pushViewController(vc, animated: true)
        
    }
}
