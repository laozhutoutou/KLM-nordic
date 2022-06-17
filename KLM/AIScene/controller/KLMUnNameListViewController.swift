//
//  KLMUnNameListViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit
import nRFMeshProvision
import SVProgressHUD

class KLMUnNameListViewController: UIViewController,  Editable{
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var currentVersion: String!
    private var versionData: KLMVersion.KLMVersionData!
    
    lazy var searchBar: UIView = {
        let width = KLMScreenW - 65 - 20
        let searchBar = UIView.init(frame: CGRect(x: width, y: KLM_StatusBarHeight + 7, width: 30, height: 30))
        searchBar.backgroundColor = .white
        let image = UIImageView.init(image: UIImage(named: "icon_search"))
        searchBar.addSubview(image)
        image.snp.makeConstraints { make in
            
            make.center.equalToSuperview()
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
        NotificationCenter.default.addObserver(self, selector: #selector(initData), name: .homeDeleteSuccess, object: nil)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_new_scene", target: self, action: #selector(newDevice))
        
        ///家庭列表按钮
        let homeItem = UIBarButtonItem.init(customView: self.homeBtn)
        navigationItem.leftBarButtonItem = homeItem
        
        //刷新
        let header = KLMRefreshHeader.init {[weak self] in
            guard let self = self else { return }
            self.initData()
        }
        self.collectionView.mj_header = header
        
    }
    
    func event() {
        
        ///检查网络
        checkNetwork()
        
        ///初始化数据
        initData()
        ///检查版本
        if apptype == .targetGN || apptype == .targetsGW {
            checkVersion()
        }
    }
    
    @objc func initData() {
        
        //蓝牙连接需要一定时间，搞个加载动画
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 2) {
            self.hideEmptyView()
        }
        
        ///先填充本地数据
        if let home = KLMMesh.loadHome() { ///本地存有家庭

            self.homeBtn.setTitle(home.meshName, for: .normal)
            self.homeBtn.layoutButton(with: .right, imageTitleSpace: 5)
            ///存储mesh数据
            KLMMesh.loadHomeMeshData(meshConfiguration: home.meshConfiguration)

            ///渲染首页
            self.setupData()
        }
        
        KLMService.getMeshList { response in

            let meshList = response as! [KLMHome.KLMHomeModel]
            if meshList.count > 0 {///服务器有家庭

                if let home = KLMMesh.loadHome(), let mesh = meshList.first(where: { $0.id == home.id }) {///本地存在和服务器也有
                    ///比较是服务器的新还是本地的新

                    let homeData = KLMMesh.getMeshNetwork(meshConfiguration: home.meshConfiguration)
                    let meshData = KLMMesh.getMeshNetwork(meshConfiguration: mesh.meshConfiguration)
                    if homeData.timestamp.timeIntervalSinceReferenceDate > meshData.timestamp.timeIntervalSinceReferenceDate { ///本地比服务器的新，提交本地的给服务器
                        KLMLog("本地比服务器的新")
                        self.commitLoalDataToServer()

                    } else if homeData.timestamp.timeIntervalSinceReferenceDate == meshData.timestamp.timeIntervalSinceReferenceDate {
                        ///本地的和服务器一样
                        KLMLog("本地和服务器的一样")
                    } else {
                        ///本地的比服务器旧，拉取服务器的数据
                        KLMLog("本地的比服务器旧")
                        let currentHome = mesh
                        self.homeBtn.setTitle(currentHome.meshName, for: .normal)
                        self.homeBtn.layoutButton(with: .right, imageTitleSpace: 5)
                        ///存储当前家庭
                        KLMMesh.saveHome(home: currentHome)
                        ///存储mesh数据
                        KLMMesh.loadHomeMeshData(meshConfiguration: currentHome.meshConfiguration)
                        ///渲染首页
                        self.setupData()
                    }

                } else {
                    ///选择第一个家庭
                    let firstHome = meshList.first!

                    self.homeBtn.setTitle(firstHome.meshName, for: .normal)
                    self.homeBtn.layoutButton(with: .right, imageTitleSpace: 5)
                    ///存储当前家庭
                    KLMMesh.saveHome(home: firstHome)
                    ///存储mesh数据
                    KLMMesh.loadHomeMeshData(meshConfiguration: firstHome.meshConfiguration)
                    ///渲染首页
                    self.setupData()
                }
                
            } else {///服务器没有家庭

                self.homeBtn.setTitle(nil, for: .normal)
                if KLMMesh.loadHome() != nil {///本地存有家庭
                    ///清空数据
                    KLMMesh.removeHome()

                    (UIApplication.shared.delegate as! AppDelegate).createNewMeshNetwork()

                }

                ///渲染首页
                self.setupData()
            }

        } failure: { error in
            
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
        
        NotificationCenter.default.post(name: .dataUpdate, object: nil)
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
        
        if apptype == .test {
            
            let vc = KLMAddDeviceTestViewController()
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        let vc = KLMAddDeviceViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func homeListClick() {
        
        SVProgressHUD.show()
        KLMService.getMeshList { response in
            SVProgressHUD.dismiss()
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
            self.currentVersion = String(format: "%@", KLM_APP_VERSION as! String)
            
            guard self.currentVersion.compare(self.versionData.fileVersion) == .orderedAscending else { //左操作数小于右操作数，需要升级
                return
            }
            
            ///是否是强制更新
            if self.versionData.isForceUpdate {///是强制更新
                
                self.showUpdateView()
                
            } else {///普通更新
                
                ///每个新版本提示一次
                guard KLMGetUserDefault(self.versionData.fileVersion) == nil else { return }
                KLMSetUserDefault(self.versionData.fileVersion, self.versionData.fileVersion)
                
                self.showUpdateView()
            }
            ///每隔一段时间提示一次
        } failure: { error in
            
        }
    }
    
    private func showUpdateView() {
        
        ///用英语
        var updateMsg: String = self.versionData.englishMessage
        if Bundle.isChineseLanguage() {///使用中文
            updateMsg =  self.versionData.updateMessage
        }
        ///弹出提示框
        let vc = UIAlertController.init(title: LANGLOC("checkUpdate"), message: "\(self.versionData.fileVersion)\n\(updateMsg)", preferredStyle: .alert)
        vc.addAction(UIAlertAction.init(title: LANGLOC("Update"), style: .default, handler: { action in
            
            ///跳转到appleStore
            let url: String = "http://itunes.apple.com/app/id\(AppleStoreID)?mt=8"
            if UIApplication.shared.canOpenURL(URL.init(string: url)!) {
                UIApplication.shared.open(URL.init(string: url)!, options: [:]) { _ in
                    
                    if self.versionData.isForceUpdate {
                        
                        ///强制更新退出APP
                        exit(0)
                    }
                }
            }
        }))
        
        ///强制更新没有取消按钮
        if self.versionData.isForceUpdate == false{
            vc.addAction(UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil))
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    private func checkNetwork() {
        
        ///检查网络是否能用
        let manager = AFNetworkReachabilityManager.shared()
        manager.setReachabilityStatusChange { status in
            switch status {
                
            case .reachableViaWWAN,
                 .reachableViaWiFi,
                 .unknown:
                print("有网")
                KLMHomeManager.sharedInstacnce.networkStatus = .NetworkStatusOK
            default:
                KLMHomeManager.sharedInstacnce.networkStatus = .NetworkStatusNotReachable
                print("没网")
            }
        }
        manager.startMonitoring()
    }
    
    private func commitLoalDataToServer() {
        
        if KLMMesh.save() {
            
        }
    }
}

extension KLMUnNameListViewController: YBPopupMenuDelegate {
    
    func ybPopupMenu(_ ybPopupMenu: YBPopupMenu!, didSelectedAt index: Int) {
        
        let selectHome = self.homes[index]
        if let home = KLMMesh.loadHome(), selectHome.id == home.id {
            return
        }
        
        //取缓存数据
        if let localHome = KLMMesh.getHome(homeId: selectHome.id) {
            KLMMesh.saveHome(home: localHome)
        } else {
            KLMMesh.saveHome(home: selectHome)
        }
        self.initData()
        
    }
}

extension KLMUnNameListViewController: KLMAINameListCellDelegate {
    
    func setItem(model: Node) {
        
        KLMHomeManager.sharedInstacnce.smartNode = model
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        KLMConnectManager.shared.connectToNode(node: model) { [weak self] in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            if apptype == .test {

                let vc = KLMTestSectionTableViewController()
                self.navigationController?.pushViewController(vc, animated: true)

                return
            }
            
            let vc = KLMDeviceEditViewController()
            self.navigationController?.pushViewController(vc, animated: true)
            
        } failure: {

        }
    }
    
    func longPress(model: Node) {
        
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        //弹出提示框
        let alert = UIAlertController(title: LANGLOC("deleteDevice"),
                                      message: LANGLOC("please confirm that you are not going to use the light again."),
                                      preferredStyle: .alert)
        let resetAction = UIAlertAction(title: LANGLOC("Remove"), style: .destructive) { _ in
            
            //弹出提示框
            let warnAlert = UIAlertController(title: LANGLOC("Warning"),
                                          message: LANGLOC("deleteDeviceTip"),
                                          preferredStyle: .alert)
            let warnresetAction = UIAlertAction(title: LANGLOC("Remove"), style: .destructive) { _ in
                
                MeshNetworkManager.instance.meshNetwork!.remove(node: model)
                if KLMMesh.save() {
                    //删除成功
                    self.setupData()
                }
            }
            let warncancelAction = UIAlertAction(title: LANGLOC("cancel"), style: .cancel)
            warnAlert.addAction(warnresetAction)
            warnAlert.addAction(warncancelAction)
            self.present(warnAlert, animated: true)
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
}

extension KLMUnNameListViewController: KLMSIGMeshManagerDelegate {
        
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node) {
        
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        
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
