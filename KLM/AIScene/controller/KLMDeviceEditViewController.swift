//
//  KLMDeviceEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit
import nRFMeshProvision

class KLMDeviceEditViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var deviceGroups = [Group]()
    
    let titles = [LANGLOC("name"),LANGLOC("Group"),LANGLOC("lightSet")]
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = KLMHomeManager.currentNode.name
        
        setupData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddToGroup, object: nil)
        
    }
    
    ///查询设备所属分组
    @objc func setupData() {
        deviceGroups = KLMHomeManager.currentModel.subscriptions
        self.tableView.reloadData()
    }
    
    @IBAction func returnTuMain(_ sender: Any) {
        
        navigationController?.popToRootViewController(animated: true)
        
    }
}

extension KLMDeviceEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 7
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
        case 0, 1, 2:
            let title: String = titles[indexPath.row]
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = title
            if indexPath.row == 0 {
                
                cell.rightTitle = KLMHomeManager.currentNode.name
                
            }
            
            if indexPath.row == 1 {
                
                if self.deviceGroups.count <= 0 {
                    let string = LANGLOC("unGroup")
                    cell.rightTitle = string
                } else {
                    var string = ""
                    for model in self.deviceGroups {
                        
                        string = string + model.name + "，"
                        
                    }
                    string.removeLast()
                    cell.rightTitle = string
                }

            }
            return cell
        case 3:
            let cell: KLMOneSwitchCell = KLMOneSwitchCell.cellWithTableView(tableView: tableView)
            return cell
        case 4:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = "Motion"
            return cell
        case 5:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = LANGLOC("restorefactorysettings")
            return cell
        default:
            break
        }
        
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = "单独控制"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0://设备名称
            let vc = CMDeviceNamePopViewController()
            vc.nametype = .nameTypeDevice
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.nameBlock = {[weak self] name in
                
                guard let self = self else { return }
                
                KLMHomeManager.currentNode.name = name
                
                if MeshNetworkManager.instance.save() {
                    
                    self.tableView.reloadData()
                }
                
                //发送通知更新首页
                NotificationCenter.default.post(name: .deviceNameUpdate, object: nil)
                
            }
            present(vc, animated: true, completion: nil)
            
        case 1://分组
            let vc = KLMGroupDeviceAddToViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        case 2://灯光设置
            
            print(1111)
        case 4:
            let vc = KLMMotionViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 5: //恢复出厂设置
            let vc = UIAlertController.init(title: "Restore factory settings", message: nil, preferredStyle: .actionSheet)
            vc.addAction(UIAlertAction.init(title: "Reset", style: .destructive, handler: { action in
                SVProgressHUD.show()
                KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode) { _ in
                    
                    SVProgressHUD.showSuccess(withStatus: "success")
                    NotificationCenter.default.post(name: .deviceReset, object: nil)
                    self.navigationController?.popToRootViewController(animated: true)
                    
                } failure: { error in
                    KLMShowError(error)
                }

            }))
            vc.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            present(vc, animated: true, completion: nil)
        default:
            let vc = KLMTestViewController()
            navigationController?.pushViewController(vc, animated: true)
            break
        }
    }
}
