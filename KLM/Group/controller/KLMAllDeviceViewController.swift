//
//  KLMAllDeviceViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/3/7.
//

import UIKit

private enum itemType: Int, CaseIterable {
    case lightPower = 0
    case motion
}

class KLMAllDeviceViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("allDevice")
    }

}

extension KLMAllDeviceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return itemType.allCases.count
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        switch indexPath.row {
        case itemType.lightPower.rawValue: ///开关
            let cell: KLMGroupPowerCell = KLMGroupPowerCell.cellWithTableView(tableView: tableView)
            cell.isAllNodes = true
            return cell
        case itemType.motion.rawValue:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("Energysavingsettings")
            return cell
        default: break
            
        }
        return UITableViewCell.init()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case itemType.motion.rawValue:
            let vc = KLMGroupMotionViewController()
            vc.isAllNodes = true
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
