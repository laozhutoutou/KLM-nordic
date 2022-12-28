//
//  KLMGroupDeviceEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit
import nRFMeshProvision

class KLMGroupDeviceEditViewController: UIViewController {
    
   
    @IBOutlet weak var tableView: UITableView!
    
    //数据源
    lazy var deviceLists: [Node] = {
        let  deviceLists = [Node]()
        return deviceLists
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        KLMMessageManager.sharedInstacnce.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = KLMHomeManager.currentGroup.name
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceTransferSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddToGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceRemoveFromGroup, object: nil)
        
        let addBar = UIButton()
        addBar.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        addBar.contentMode = .scaleAspectFit
        addBar.setImage(UIImage(named: "icon_group_new_scene"), for: .normal)
        addBar.addTarget(self, action: #selector(addDevice), for: .touchUpInside)
        
        let addView = UIView(frame: addBar.frame)
        addView.addSubview(addBar)
        let addBarItem = UIBarButtonItem(customView: addView)
        
        let moreBar = UIButton()
        moreBar.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        moreBar.contentMode = .scaleAspectFit
        moreBar.setTitle("•••", for: .normal)
        moreBar.setTitleColor(.black, for: .normal)
        moreBar.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        moreBar.addTarget(self, action: #selector(more), for: .touchUpInside)
        
        let moreView = UIView(frame: moreBar.frame)
        moreView.addSubview(moreBar)
        let moreBarItem = UIBarButtonItem(customView: moreView)
        
        let tempBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        tempBarItem.width = 15
        navigationItem.rightBarButtonItems = [moreBarItem, tempBarItem, addBarItem]
        
//        let addBar = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(addDevice))
//        let tempBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
//        tempBarItem.width = 25
        //        let addBar = UIBarButtonItem.init(title: "+", target: self, action: #selector(addDevice))
        //        let moreBar = UIBarButtonItem.init(title: "...", target: self, action: #selector(more))
//        let moreBar = UIBarButtonItem.init(icon: "icon_more_unselect", target: self, action: #selector(more))
//        navigationItem.rightBarButtonItems = [moreBar, tempBarItem, addBar]
        
        setupData()
        
    }
    
    @objc func setupData(){
        
        let network = MeshNetworkManager.instance.meshNetwork!
        let models = network.models(subscribedTo: KLMHomeManager.currentGroup)
        self.deviceLists.removeAll()
        for model in models {
            
            let node = KLMHomeManager.getNodeFromModel(model: model)
            self.deviceLists.append(node!)
        }
        self.tableView.reloadData()
    }
    
    @objc func addDevice() {
        
        let vc = KLMGroupDeviceAddTableViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func more() {
        
        let point: CGPoint = CGPoint.init(x: KLMScreenW - 30, y: KLM_TopHeight)
        let titles: [String] = [LANGLOC("Delete devices"), LANGLOC("Devices transfer")]
        YBPopupMenu.show(at: point, titles: titles, icons: nil, menuWidth: 150) { popupMenu in
            popupMenu?.priorityDirection = .right
            popupMenu?.arrowHeight = 0
            popupMenu?.minSpace = 30
            popupMenu?.isShadowShowing = false
            popupMenu?.delegate = self
            popupMenu?.cornerRadius = 0
        }
    }
}

extension KLMGroupDeviceEditViewController: YBPopupMenuDelegate {
    
    func ybPopupMenu(_ ybPopupMenu: YBPopupMenu!, didSelectedAt index: Int) {
        
        if index == 0 {
            let vc = KLMGroupDeleteDevicesController()
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = KLMGroupDeleteDevicesController()
            vc.isFromTransfer = true
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension KLMGroupDeviceEditViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.deviceLists.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let deviceModel:  Node = self.deviceLists[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.leftImage = deviceModel.icon
        cell.leftTitle = deviceModel.nodeName
        return cell
    
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let node = self.deviceLists[indexPath.row]
        
        //记录当前设备
        KLMHomeManager.sharedInstacnce.smartNode = node
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        KLMConnectManager.shared.connectToNode(node: node) { [weak self] in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            if apptype == .test {
                
                let vc = KLMTestSectionTableViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                
                return
            }
            
            if node.isController {
                
                let vc = KLMControllerSettingViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            let vc = KLMDeviceEditViewController()
            self.navigationController?.pushViewController(vc, animated: true)
            
        } failure: {
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let deviceModel: Node = self.deviceLists[indexPath.item]

        let deleteAction = UIContextualAction.init(style: .destructive, title: LANGLOC("Delete")) { action, sourceView, completionHandler in

            let aler = UIAlertController.init(title: LANGLOC("Delete devices"), message: nil, preferredStyle: .alert)
            let cancel = UIAlertAction.init(title: LANGLOC("Cancel"), style: .cancel, handler: nil)
            let sure = UIAlertAction.init(title: LANGLOC("Confirm"), style: .default) { action in

                if KLMMesh.isCanEditMesh() == false {
                    return
                }
                
                SVProgressHUD.show()
                KLMConnectManager.shared.connectToNode(node: deviceModel) { [weak self] in
                    guard let self = self else { return }
                    SVProgressHUD.dismiss()
                    
                    //设备从当前群组中移除
                    KLMMessageManager.sharedInstacnce.deleteNodeToGroup(withNode: deviceModel, withGroup: KLMHomeManager.currentGroup)
                    
                } failure: {
                    
                }
            }
            aler.addAction(cancel)
            aler.addAction(sure)
            self.present(aler, animated: true, completion: nil)

            completionHandler(true)
        }

        //转移
        let editAction = UIContextualAction.init(style: .normal, title: LANGLOC("Transfer")) { action, sourceView, completionHandler in
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            SVProgressHUD.show()
            KLMConnectManager.shared.connectToNode(node: deviceModel) { [weak self] in
                guard let self = self else { return }
                SVProgressHUD.dismiss()
                
                let vc = KLMGroupTransferListViewController()
                vc.selectNodes = [deviceModel]
                self.navigationController?.pushViewController(vc, animated: true)
                
            } failure: {
                
            }

            completionHandler(true)
        }

        editAction.backgroundColor = appMainThemeColor
        let actions = UISwipeActionsConfiguration.init(actions: [deleteAction, editAction])
        return actions
    }
}

extension KLMGroupDeviceEditViewController: KLMMessageManagerDelegate {

    func messageManager(_ manager: KLMMessageManager, didHandleGroup unicastAddress: Address, error: MessageError?) {

        if error != nil {

            SVProgressHUD.showInfo(withStatus: error?.message)
            return
        }
        ///提交到服务器
        if KLMMesh.save() {

        }

        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
        NotificationCenter.default.post(name: .deviceRemoveFromGroup, object: nil)

        self.setupData()
    }

}

extension KLMGroupDeviceEditViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {

        let contentView = UIView()
        
        let image = UIImageView.init(image: UIImage.init(named: "img_Empty_Status"))
        contentView.addSubview(image)
        image.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        let titleLab = UILabel()
        titleLab.text = LANGLOC("No devices")
        titleLab.font = UIFont.systemFont(ofSize: 14)
        titleLab.textColor = rgba(0, 0, 0, 0.5)
        contentView.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(image.snp.bottom).offset(10)
        }
        
        return contentView
    }
}

