//
//  KLMCustomerCountingTableViewController.swift
//  KLM
//
//  Created by 朱雨 on 2023/1/10.
//

import UIKit

class KLMCustomerCountingTableViewController: UITableViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Customer Counting")
        tableView.rowHeight = 50
    }

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
            cell.leftTitle = LANGLOC("Wi-Fi Configuration")
        } else {
            cell.leftTitle = LANGLOC("View Customer Counting")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToNode(node: KLMHomeManager.currentNode) { [weak self] in
                guard let self = self else { return }
                SVProgressHUD.dismiss()
                
                let vc = KLMCustomerCountingWiFiViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                
            } failure: {
                
            }
            
        } else {
            
        }
    }
    
}
