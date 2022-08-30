//
//  KLMGroupViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//
// 测试看看
import UIKit
import nRFMeshProvision

class KLMGroupViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var groups: [Group] = [Group]()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_group_new_scene", target: self, action: #selector(moreClick))
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .groupRenameSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .groupAddSuccess, object: nil)    
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceRemoveFromGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddToGroup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceTransferSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceReset, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .dataUpdate, object: nil)
        //刷新
        let header = KLMRefreshHeader.init {
            
            NotificationCenter.default.post(name: .mainPageRefresh, object: nil)

        }
        self.tableView.mj_header = header
        
        setupData()
    }
    
    @objc func setupData() {
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            self.groups = network.groups
            self.tableView.reloadData()
        }
        self.tableView.mj_header?.endRefreshing()
    }
    
    /// 更多
    @objc func moreClick() {
                
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        let vc = CMDeviceNamePopViewController()
        vc.titleName = LANGLOC("Group")
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        vc.nameBlock = {[weak self] name in
            SVProgressHUD.show()
            guard let self = self else { return }
            
            if let network = MeshNetworkManager.instance.meshNetwork,
               let localProvisioner = network.localProvisioner {
                
                if let automaticAddress = network.nextAvailableGroupAddress(for: localProvisioner) {
                    
                    let address = MeshAddress(automaticAddress)
                    let group = try? Group(name: name, address: address)
                    try? network.add(group: group!)
                    
                    if KLMMesh.save() {
                        
                        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                        self.setupData()
                        
                        let mesh = KLMMesh.loadHome()!
                        //提交分组到服务器
                        KLMService.addGroup(meshId: mesh.id, groupId: Int(automaticAddress), groupName: name) { response in
                            KLMLog("分组提交成功到服务器")

                        } failure: { error in
                            KLMHttpShowError(error)
                        }
                    }
                }
            }
        }
        self.tabBarController?.present(vc, animated: true, completion: nil)
        
    }

}

extension KLMGroupViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return groups.count + 1

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 64
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 { ///所有设备
            
            let cell: KLMGroupAllDeviceCell = KLMGroupAllDeviceCell.cellWithTableView(tableView: tableView)
            cell.settingsBlock = {[weak self] in
                
                guard let self = self else { return }
                if KLMMesh.isLoadMesh() == false {
                    SVProgressHUD.showInfo(withStatus: LANGLOC("CreateHomeTip"))
                    return
                }
                
                KLMHomeManager.sharedInstacnce.controllType = .AllDevices
                let vc = KLMAllDeviceViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
            return cell
        }
        
        let model: Group = groups[indexPath.row - 1]
        let cell = KLMGroupCell.cellWithTableView(tableView: tableView)
        cell.model = model
        cell.settingsBlock = {[weak self] cellGroup in
            
            guard let self = self else { return }
            
            KLMHomeManager.sharedInstacnce.smartGroup = cellGroup
            
            let vc = KLMGroupEditViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 { ///所有设备
            
            if KLMMesh.isLoadMesh() == false {
                SVProgressHUD.showInfo(withStatus: LANGLOC("CreateHomeTip"))
                return
            }
            
            KLMHomeManager.sharedInstacnce.controllType = .AllDevices
            
            SVProgressHUD.show()
            SVProgressHUD.setDefaultMaskType(.black)
            KLMConnectManager.shared.connectToAllNodes { [weak self] in
                SVProgressHUD.dismiss()
                guard let self = self else { return }
                //是否有相机权限
                KLMPhotoManager().photoAuthStatus { [weak self] in
                    guard let self = self else { return }

                    let vc = KLMImagePickerController()
                    vc.sourceType = .camera
                    self.present(vc, animated: true, completion: nil)

                }
            } failure: {
                
            }
            return
        }
        
        let model: Group = groups[indexPath.row - 1]
        KLMHomeManager.sharedInstacnce.smartGroup = model
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        KLMConnectManager.shared.connectToGroup(group: model) { [weak self] in
            
            guard let self = self else { return }
            //是否有相机权限
            KLMPhotoManager().photoAuthStatus { [weak self] in
                guard let self = self else { return }

                let vc = KLMImagePickerController()
                vc.sourceType = .camera
                self.tabBarController?.present(vc, animated: true, completion: nil)

            }
        } failure: {
            
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.row == 0 {
            
            return nil
        }
        
        let model: Group = groups[indexPath.row - 1]
        
        let deleteAction = UIContextualAction.init(style: .destructive, title: LANGLOC("delete")) { action, sourceView, completionHandler in
            
            if KLMMesh.isCanEditMesh() == false {
                return
            }
            
            let aler = UIAlertController.init(title: LANGLOC("groupDeleteTip"), message: LANGLOC("groupSelectDelete"), preferredStyle: .alert)
            let cancel = UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil)
            let sure = UIAlertAction.init(title: LANGLOC("sure"), style: .default) { action in
                
                let network = MeshNetworkManager.instance.meshNetwork!
                let models = network.models(subscribedTo: model)
                if models.count > 0 { //组里有设备不能删除
                    SVProgressHUD.showInfo(withStatus: LANGLOC("Please remove all lights from the group"))
                    return
                }
                SVProgressHUD.show()
                KLMService.deleteGroup(groupId: Int(model.address.address)) { response in
                    
                    do {
                        try network.remove(group: model)
                        if KLMMesh.save() {
                            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                            self.setupData()
                        }
                    } catch {
                        var erro = MessageError()
                        erro.message = error.localizedDescription
                        if let err = error as? MeshNetworkError{
                            switch err {
                            case .groupInUse: ///组里有设备
                                erro.message = LANGLOC("Please remove all lights from the group")
                            default:
                                break
                            }
                        }
                        KLMShowError(erro)
                    }
                } failure: { error in
                    
                    KLMHttpShowError(error)
                }
                
            }
            aler.addAction(cancel)
            aler.addAction(sure)
            self.tabBarController?.present(aler, animated: true, completion: nil)
            
            completionHandler(true)
        }
        
        let actions = UISwipeActionsConfiguration.init(actions: [deleteAction])
        return actions
    }
}

extension KLMGroupViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {

        let contentView = UIView()
        
        let addBtn = UIButton()
        addBtn.backgroundColor = appMainThemeColor
        addBtn.setTitleColor(.white, for: .normal)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        addBtn.setTitle(LANGLOC("newGroup"), for: .normal)
        addBtn.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
        addBtn.layer.cornerRadius = 20
        contentView.addSubview(addBtn)
        addBtn.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(150)
            make.height.equalTo(40)
        }
        
        let titleLab = UILabel()
        titleLab.text = LANGLOC("noGroup")
        titleLab.font = UIFont.systemFont(ofSize: 14)
        titleLab.textColor = rgba(0, 0, 0, 0.5)
        contentView.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(addBtn.snp.top).offset(-20)
        }
        
        let image = UIImageView.init(image: UIImage.init(named: "img_Empty_Status"))
        contentView.addSubview(image)
        image.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(titleLab.snp.top).offset(-20)
        }
        return contentView
    }
}


