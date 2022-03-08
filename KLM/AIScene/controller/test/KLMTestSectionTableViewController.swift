//
//  KLMTestSectionTableViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/25.
//

import UIKit

class KLMTestSectionTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.rowHeight = 50
        
        sendFlash()
    }
    
    //灯闪烁
    func sendFlash() {
        
        let parame = parameModel(dp: .flash, value: 2)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 4
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "PCBA测试"
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "成品测试"
        } else if indexPath.row == 2 {
            cell.textLabel?.text = "老化测试"
        } else {
            cell.textLabel?.text = "包装测试"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            //pcba
//            let vc = KLMPCBASectionTableViewController()
//            navigationController?.pushViewController(vc, animated: true)
            
            let vc = KLMPCBASensorViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        } else if indexPath.row == 1 {
            //成品
            let vc = KLMChengpinViewController()
            navigationController?.pushViewController(vc, animated: true)

        } else if indexPath.row == 2 {//老化
            let vc = KLMLaoHuaTestViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        } else {//包装
            
            let vc = KLMBaoZhuangTestViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
