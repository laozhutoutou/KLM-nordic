//
//  KLMUnNameListViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit
import nRFMeshProvision
import SVProgressHUD

class KLMUnNameListViewController: UIViewController{
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var currentVersion: String!
    private var versionData: KLMVersion.KLMVersionData!
    
    lazy var searchBar: UIView = {
        let width = 100.0
        let searchBar = UIView.init(frame: CGRect(x: width, y: KLM_StatusBarHeight + 7, width: KLMScreenW - width - 65, height: 30))
        searchBar.backgroundColor = .white
        searchBar.layer.cornerRadius = 15
        searchBar.clipsToBounds = true
        let image = UIImageView.init(image: UIImage(named: "icon_search"))
        searchBar.addSubview(image)
        image.snp.makeConstraints { make in
            make.left.equalTo(9)
            make.centerY.equalToSuperview()
        }
        let titleLab = UILabel()
        titleLab.text = LANGLOC("searchDeviceName")
        titleLab.font = UIFont.systemFont(ofSize: 14)
        titleLab.textColor = rgba(0, 0, 0, 0.3)
        searchBar.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.left.equalTo(image.snp.right).offset(10)
            make.centerY.equalToSuperview()
        }
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(tapSearch))
        searchBar.addGestureRecognizer(tap)
        return searchBar
    }()
    
    lazy var homeBtn: UIButton = {
        let homeBtn = UIButton.init(type: .custom)
        homeBtn.frame = CGRect.init(x: 0, y: 0, width: 100, height: 18)
        homeBtn.contentHorizontalAlignment = .left
        homeBtn.setTitleColor(.black, for: .normal)
        homeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        homeBtn.setImage(UIImage.init(named: "icon_arrowDown"), for: .normal)
        homeBtn.layoutButton(with: .right, imageTitleSpace: 5)
        homeBtn.addTarget(self, action: #selector(homeListClick), for: .touchUpInside)
        return homeBtn
    }()
    
    //设备数据源
    var nodes: [Node] = [Node]()
    //家庭数据源
    var homes: [KLMHome.KLMHomeModel] = []
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barTintColor =  rgba(247, 247, 247, 1)
        self.searchBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.navigationBar.barTintColor = navigationBarColor
        self.searchBar.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
          
        setupUI()
        
        event()
    
    }
    
    func setupUI() {
        
        collectionView.backgroundColor = appBackGroupColor
        
        navigationController?.view.addSubview(self.searchBar)
        
        self.collectionView.register(UINib(nibName: String(describing: KLMAINameListCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: KLMAINameListCell.self))
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceNameUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceReset, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(initData), name: .homeAddSuccess, object: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_new_scene", target: self, action: #selector(newDevice))
        
        ///家庭列表按钮
        let homeItem = UIBarButtonItem.init(customView: self.homeBtn)
        navigationItem.leftBarButtonItem = homeItem
        
        //刷新
        let header = KLMRefreshHeader.init {[weak self] in
            guard let self = self else { return }
            (UIApplication.shared.delegate as! AppDelegate).enterMainUI()
        }
        self.collectionView.mj_header = header
    }
    
    func event() {
        
        ///初始化数据
        initData()
        ///检查版本
        checkVersion()
    }
    
    @objc func initData() {
        
        KLMService.getMeshList { response in
            
            let meshList = response as! [KLMHome.KLMHomeModel]
            if meshList.count > 0 {///服务器有家庭
                
                var currentHome: KLMHome.KLMHomeModel!
                
                if let home = KLMMesh.loadHome(), let mesh = meshList.first(where: { $0.id == home.id }) {///本地存在和服务器也有
                    
                    currentHome = mesh

                } else {
                    ///选择第一个家庭
                    currentHome = meshList.first!
                }
                
                self.homeBtn.setTitle(currentHome.meshName, for: .normal)
                ///存储当前家庭
                KLMMesh.saveHome(home: currentHome)
                ///存储mesh数据
                KLMMesh.loadHomeMeshData(meshConfiguration: currentHome.meshConfiguration)
                ///渲染首页
                self.setupData()
                
            } else {///服务器没有家庭
                
                if KLMMesh.loadHome() != nil {///本地存有家庭
                    ///清空数据
                    KLMMesh.removeHome()
                    self.homeBtn.setTitle(nil, for: .normal)
                    (UIApplication.shared.delegate as! AppDelegate).createNewMeshNetwork()
                    ///渲染首页
                    self.setupData()
                }
            }
            
        } failure: { error in
            ///获取不到服务器数据，加载本地数据
            if let home = KLMMesh.loadHome() { ///本地存有家庭
                
                self.homeBtn.setTitle(home.meshName, for: .normal)
                ///从本地提取mesh数据
                KLMMesh.loadLocalMeshData()
                ///渲染首页
                self.setupData()
                
            }
        }
    }

    @objc func setupData(){
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            
            self.nodes.removeAll()
            self.nodes = notConfiguredNodes
            self.collectionView.reloadData()
        }
        
        self.collectionView.mj_header?.endRefreshing()
    }
    
    @objc func tapSearch() {
        
        let vc = KLMSearchViewController()
        let nav = KLMNavigationViewController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
        
    }
    
    @objc func newDevice() {
        
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        let vc = KLMAddDeviceViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func homeListClick() {
        
        KLMService.getMeshList { response in
            
            self.homes = response as! [KLMHome.KLMHomeModel]
            self.showHomeDropView()
        } failure: { error in
            KLMHttpShowError(error)
        }
    }
    
    func showHomeDropView() {
        
        let point: CGPoint = CGPoint.init(x: 20, y: KLM_TopHeight)
        var titles: [String] = []
        for model in self.homes {
            titles.append(model.meshName)
        }
        guard titles.count > 0 else { return }
        YBPopupMenu.show(at: point, titles: titles, icons: nil, menuWidth: 100) { popupMenu in
            popupMenu?.priorityDirection = .none
            popupMenu?.arrowPosition = 1
            popupMenu?.arrowHeight = 0
            popupMenu?.dismissOnSelected = true
            popupMenu?.isShadowShowing = false
            popupMenu?.delegate = self
        }
    }
    
    private func checkVersion() {
        
        KLMService.checkVersion(type: "ios") { response in
            
            guard let data = response as? KLMVersion.KLMVersionData else { return  }
            self.versionData = data
            self.currentVersion = String(format: "V%@", KLM_APP_VERSION as! String)
            
            guard self.currentVersion.compare(self.versionData.fileVersion) == .orderedAscending else { //左操作数小于右操作数，需要升级
                return
            }
            
            ///是否是强制更新
            let isForce: Bool = false
            if isForce {///是强制更新
                
                self.showUpdateView()
                
            } else {///普通更新
                
                ///每个新版本提示一次
//                guard KLMGetUserDefault(self.versionData.fileVersion) == nil else { return }
//                KLMSetUserDefault(self.versionData.fileVersion, self.versionData.fileVersion)
                
                self.showUpdateView()
            }
            ///每隔一段时间提示一次
        } failure: { error in
            
        }
    }
    
    private func showUpdateView() {
        
        ///用英语
        var updateMsg: String = self.versionData.updateMessage
//        if Bundle.isChineseLanguage() {///使用中文
//
//        }
        ///弹出提示框
        let vc = UIAlertController.init(title: LANGLOC("checkUpdate"), message: "\(self.versionData.fileVersion)\n\(updateMsg)", preferredStyle: .alert)
        vc.addAction(UIAlertAction.init(title: LANGLOC("Update"), style: .default, handler: { action in
            
            SVProgressHUD.showInfo(withStatus: "功能未完善")
            ///跳转到appleStore
//            let url: String = "http://itunes.apple.com/app/id1590631426?mt=8"
//            if UIApplication.shared.canOpenURL(URL.init(string: url)!) {
//                UIApplication.shared.open(URL.init(string: url)!, options: [:], completionHandler: nil)
//            }
            
            ///强制更新退出APP
//            exit(0)
            
        }))
        
        ///强制更新没有取消按钮
        vc.addAction(UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil))
        self.present(vc, animated: true, completion: nil)
    }
}

extension KLMUnNameListViewController: YBPopupMenuDelegate {
    
    func ybPopupMenu(_ ybPopupMenu: YBPopupMenu!, didSelectedAt index: Int) {
        
        let selectHome = self.homes[index]
        if let home = KLMMesh.loadHome(), selectHome.id == home.id {
            return
        }
        
        ///存储当前家庭
        KLMMesh.saveHome(home: selectHome)
        self.homeBtn.setTitle(selectHome.meshName, for: .normal)
        ///将mesh信息存到本地
        KLMMesh.loadHomeMeshData(meshConfiguration: selectHome.meshConfiguration)
        ///渲染页面
        (UIApplication.shared.delegate as! AppDelegate).enterMainUI()
    }
}

extension KLMUnNameListViewController: KLMAINameListCellDelegate {
    
    func setItem(model: Node) {
        
        KLMHomeManager.sharedInstacnce.smartNode = model
        
        if !MeshNetworkManager.bearer.isOpen {
            SVProgressHUD.showInfo(withStatus: "Connecting...")
            return
        }
        if !model.isCompositionDataReceived {
            //对于未composition的进行配置
            SVProgressHUD.show(withStatus: "Composition")
            SVProgressHUD.setDefaultMaskType(.black)
            
            KLMSIGMeshManager.sharedInstacnce.delegate = self
            KLMSIGMeshManager.sharedInstacnce.getCompositionData(node: model)
            return
        }
        
        if isTestApp {
            
            let vc = KLMTestSectionTableViewController()
            navigationController?.pushViewController(vc, animated: true)
            
            return
        }
        
        let vc = KLMDeviceEditViewController()
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func longPress(model: Node) {
        
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        let alert = UIAlertController(title: LANGLOC("deleteDevice"),
                                      message: LANGLOC("deleteDeviceTip"),
                                      preferredStyle: .actionSheet)
        let resetAction = UIAlertAction(title: LANGLOC("delete"), style: .destructive) { _ in
            MeshNetworkManager.instance.meshNetwork!.remove(node: model)
            
            if KLMMesh.save() {
                //删除成功
                self.setupData()
            } 
        }
        let cancelAction = UIAlertAction(title: LANGLOC("cancel"), style: .cancel)
        alert.addAction(resetAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

extension KLMUnNameListViewController: UICollectionViewDelegate, UICollectionViewDataSource,  UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.nodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let itemWidth: CGFloat = (KLMScreenW - 16*2 - 15) / 2
        let itemHeight: CGFloat = 174.0
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let node = self.nodes[indexPath.item]
        let cell: KLMAINameListCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: KLMAINameListCell.self), for: indexPath) as! KLMAINameListCell
        cell.model = node
        cell.delegate = self
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let node = self.nodes[indexPath.item]
        
        //记录当前设备
        KLMHomeManager.sharedInstacnce.smartNode = node
        
        if !MeshNetworkManager.bearer.isOpen {
            SVProgressHUD.showInfo(withStatus: "Connecting...")
            return
        }
        if !node.isCompositionDataReceived {
            //对于未composition的进行配置
            SVProgressHUD.show(withStatus: "Composition")
            SVProgressHUD.setDefaultMaskType(.black)
            
            KLMSIGMeshManager.sharedInstacnce.delegate = self
            KLMSIGMeshManager.sharedInstacnce.getCompositionData(node: node)
            return
        }
        
        if isTestApp {
            
            let vc = KLMTestSectionTableViewController()
            navigationController?.pushViewController(vc, animated: true)
            
            return
        }
        
//        是否有相机权限
        KLMPhotoManager().photoAuthStatus { [weak self] in
            guard let self = self else { return }

            let vc = KLMImagePickerController()
            vc.sourceType = UIImagePickerController.SourceType.camera
            self.tabBarController?.present(vc, animated: true, completion: nil)

        }
    }
}

extension KLMUnNameListViewController: KLMSIGMeshManagerDelegate {
        
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node) {
        
        SVProgressHUD.showSuccess(withStatus: "Please tap again")
        
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?){
        
        KLMShowError(error)
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didSendMessage message: MeshMessage) {
        
        SVProgressHUD.show(withStatus: "Did send message")
    }
}
 
extension KLMUnNameListViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        
        return true
    }
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {

        let contentView = UIView()
        
        let addBtn = UIButton()
        addBtn.backgroundColor = appMainThemeColor
        addBtn.setTitleColor(.white, for: .normal)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        addBtn.setTitle(LANGLOC("addDevice"), for: .normal)
        addBtn.addTarget(self, action: #selector(newDevice), for: .touchUpInside)
        addBtn.layer.cornerRadius = 20
        contentView.addSubview(addBtn)
        addBtn.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(140)
            make.height.equalTo(40)
        }
        
        let titleLab = UILabel()
        titleLab.text = LANGLOC("noDevice")
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



