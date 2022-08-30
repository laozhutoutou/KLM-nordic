//
//  KLMLightSettingController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/30.
//

import UIKit

private enum itemType: Int, CaseIterable {
    case picture = 0
    case custome
    case light
}

class KLMLightSettingController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("lightSet")
        tableView.rowHeight = 50
        tableView.separatorStyle = .none
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return itemType.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        switch indexPath.row {
        case itemType.picture.rawValue:
            cell.leftTitle = LANGLOC("Take a picture")
        case itemType.custome.rawValue:
            cell.leftTitle = LANGLOC("custom")
        case itemType.light.rawValue:
            cell.leftTitle = LANGLOC("Brightness")
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case itemType.picture.rawValue:
            //是否有相机权限
            KLMPhotoManager().photoAuthStatus { [weak self] in
                guard let self = self else { return }
                
                let vc = KLMImagePickerController()
                vc.sourceType = .camera
                self.present(vc, animated: true, completion: nil)
                
            }
        case itemType.custome.rawValue:
            let vc = KLMCustomViewController()
            let nav = KLMNavigationViewController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        case itemType.light.rawValue:
            let vc = KLMBrightnessViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
