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
    
    /// 是否第一次进来
    var cameraPowerFirst = true
    
    var cameraSwitch = 1
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = KLMHomeManager.currentNode.name
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        setupData()
        
        setupNodeMessage()
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddToGroup, object: nil)
        
    }
    
    ///查询设备所属分组
    @objc func setupData() {
        deviceGroups = KLMHomeManager.currentModel.subscriptions
        self.tableView.reloadData()
    }
    
    func setupNodeMessage() {
        
        //获取开关状态
        let parameTime = parameModel(dp: .cameraPower)
        KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func returnTuMain(_ sender: Any) {
        
        navigationController?.popToRootViewController(animated: true)
        
    }
}

extension KLMDeviceEditViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        if message?.dp ==  .cameraPower{
            
            if cameraPowerFirst {
                cameraPowerFirst = false
                
                let value = message?.value as! Int
                
                self.cameraSwitch = value
                self.tableView.reloadData()
            }
            
        }
        KLMLog("success")
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
        
        SVProgressHUD.showSuccess(withStatus: "success")
        NotificationCenter.default.post(name: .deviceReset, object: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMDeviceEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 8
        
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
                
                cell.rightTitle = KLMHomeManager.currentNode.nodeName
                
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
            cell.cameraOnOff = self.cameraSwitch
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
        case 6:
            let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
            cell.isShowLeftImage = false
            cell.leftTitle = "单独控制"
            return cell
        default:
            break
        }
        
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        cell.leftTitle = "测试"
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
            //是否有相机权限
            KLMPhotoManager().photoAuthStatus { [weak self] in
                guard let self = self else { return }
                
                let vc = KLMImagePickerController()
                vc.sourceType = UIImagePickerController.SourceType.camera
                self.tabBarController?.present(vc, animated: true, completion: nil)
                
            }
            
        case 4:
            let vc = KLMMotionViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 5: //恢复出厂设置
            let vc = UIAlertController.init(title: "Restore factory settings", message: nil, preferredStyle: .actionSheet)
            vc.addAction(UIAlertAction.init(title: "Reset", style: .destructive, handler: { action in
                SVProgressHUD.show()
                KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)

            }))
            vc.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            present(vc, animated: true, completion: nil)
        case 6://六路测试
            let vc = KLMTestViewController()
            navigationController?.pushViewController(vc, animated: true)
        case 7:
            let vc = KLMText1ViewController()
            navigationController?.pushViewController(vc, animated: true)
        default:
            
            break
        }
    }
}
