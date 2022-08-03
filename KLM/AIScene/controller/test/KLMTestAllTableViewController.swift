//
//  KLMTestAllTableViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/1.
//

import UIKit

class KLMTestAllTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
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
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        if indexPath.row == 0 {
            cell.leftTitle = "批量复位"
        } else {
            cell.leftTitle = "批量看图像"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = KLMSelectNodesViewController()
        vc.isFromImage = indexPath.row == 0 ? false : true
        navigationController?.pushViewController(vc, animated: true)
    }

}
