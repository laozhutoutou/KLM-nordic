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
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "半成品测试"
        } else {
            cell.textLabel?.text = "成品测试"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            //半成品
            let vc = KLMBanchenpinViewController()
            navigationController?.pushViewController(vc, animated: true)
//            let nav = KLMNavigationViewController.init(rootViewController: vc)
//            nav.modalPresentationStyle = .fullScreen
//            present(nav, animated: true, completion: nil)
            
        } else {
            //成品
            let vc = KLMChengpinViewController()
            navigationController?.pushViewController(vc, animated: true)
//            let nav = KLMNavigationViewController.init(rootViewController: vc)
//            nav.modalPresentationStyle = .fullScreen
//            present(nav, animated: true, completion: nil)
        }
    }
    
}
