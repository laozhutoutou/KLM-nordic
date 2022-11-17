//
//  KLMUnNameListViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit
import nRFMeshProvision
import SVProgressHUD

private enum DeviceType {
    case deviceTypeLight
    case deviceTypeController
}

class KLMUnNameListViewController: UIViewController,  Editable{
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var currentVersion: String!
    private var versionData: KLMVersion.KLMVersionData!
    
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
    
    @IBOutlet weak var trackLightBtn: UIButton!
    @IBOutlet weak var controllerBtn: UIButton!
    
    private var deviceType: DeviceType = .deviceTypeLight {
        didSet {
            trackLightBtn.isSelected = deviceType == .deviceTypeLight ? true : false
            controllerBtn.isSelected = deviceType == .deviceTypeLight ? false : true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.barTintColor =  rgba(247, 247, 247, 1)
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.navigationBar.barTintColor = navigationBarColor

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
          
        setupUI()
        
        event()
    }
        
    func setupUI() {
        
        collectionView.backgroundColor = appBackGroupColor
        
        self.collectionView.register(UINib(nibName: String(describing: KLMAINameListCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: KLMAINameListCell.self))
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceNameUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceReset, object: nil) 
        NotificationCenter.default.addObserver(self, selector: #selector(initData), name: .homeAddSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(initData), name: .homeDeleteSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(initData), name: .mainPageRefresh, object: nil)
        
        let addBtn: UIBarButtonItem = UIBarButtonItem.init(icon: "icon_new_scene", target: self, action: #selector(newDevice))
        let searchBtn: UIBarButtonItem = UIBarButtonItem.init(icon: "icon_search", target: self, action: #selector(tapSearch))
        let negativeSpacer: UIBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        negativeSpacer.width = 0
        navigationItem.rightBarButtonItems = [addBtn, negativeSpacer, searchBtn]
        
        ///家庭列表按钮
        let homeItem = UIBarButtonItem.init(customView: self.homeBtn)
        navigationItem.leftBarButtonItem = homeItem
        
        //刷新
        let header = KLMRefreshHeader.init {[weak self] in
            guard let self = self else { return }
            self.initData()
        }
        self.collectionView.mj_header = header
        
        ///设备是否在线
        KLMMeshNetworkManager.shared.onlineDelegate = self
        
        deviceType = .deviceTypeLight
        
    }
    
    func event() {
        
        ///检查网络
        checkNetwork()
        
        ///初始化数据
        initData()
        
        ///检查版本
        if apptype == .targetGN || apptype == .targetsGW {
            checkAPPVersion()
        }
        
        if apptype == .targetSensetrack {
            checkAppleStoreVersion()
        }
    }
    
    @objc func initData() {
        
        //蓝牙连接需要一定时间，搞个加载动画
        showEmptyView()
        
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
            
            self.hideEmptyView()
            
            let meshList = response as! [KLMHome.KLMHomeModel]
            if meshList.count > 0 {///服务器有家庭
                
                if var home = KLMMesh.loadHome(), let mesh = meshList.first(where: { $0.id == home.id }) {///本地存在和服务器也有
                    ///比较是服务器的新还是本地的新
                    let homeData = KLMMesh.getMeshNetwork(meshConfiguration: home.meshConfiguration)
                    let meshData = KLMMesh.getMeshNetwork(meshConfiguration: mesh.meshConfiguration)
                    if homeData.timestamp.timeIntervalSinceReferenceDate > meshData.timestamp.timeIntervalSinceReferenceDate { ///本地比服务器的新，提交本地的给服务器
                        KLMLog("本地比服务器的新")
                        self.commitLoalDataToServer()
                        //变更mesh中管理员ID
                        home.adminId = mesh.adminId
                        KLMMesh.saveHome(home: home)
                    } else if homeData.timestamp.timeIntervalSinceReferenceDate == meshData.timestamp.timeIntervalSinceReferenceDate {
                        ///本地的和服务器一样
                        KLMLog("本地和服务器的一样")
                        KLMMesh.saveHome(home: mesh)
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
            self.hideEmptyView()
            KLMHttpShowError(error)
        }
    }

    @objc func setupData(){
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            ///所有设备
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            
            self.nodes.removeAll()
            if deviceType == .deviceTypeLight {
                self.nodes = notConfiguredNodes.filter({ $0.isCamera})
            } else {
                self.nodes = notConfiguredNodes.filter({ $0.isController})
            }
//            self.nodes = notConfiguredNodes
            self.collectionView.reloadData()
        }
        
        self.collectionView.mj_header?.endRefreshing()
        NotificationCenter.default.post(name: .dataUpdate, object: nil)
    }
    
    @objc func tapSearch() {
        
        if apptype == .test {
            
            let vc = KLMTestAllTableViewController()
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        
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
        SVProgressHUD.setDefaultMaskType(.black)
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
        YBPopupMenu.show(at: point, titles: titles, icons: nil, menuWidth: 150) { popupMenu in
//            popupMenu?.tableView.showsVerticalScrollIndicator = true
            popupMenu?.priorityDirection = .none
            popupMenu?.arrowPosition = 1
            popupMenu?.arrowHeight = 0
            popupMenu?.dismissOnSelected = true
            popupMenu?.isShadowShowing = false
            popupMenu?.delegate = self
        }
    }
    
    private func checkAPPVersion() {
        
        KLMService.checkAPPVersion { response in
            
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
            
        } failure: { error in
            
        }
    }
    
    private func checkAppleStoreVersion() {
        
        KLMService.checkAppleStoreAppVersion { response in
            
            guard let newVersion = response as? String else { return  }
            let currentVersion = String(format: "%@", KLM_APP_VERSION as! String)
            
            guard currentVersion.compare(newVersion) == .orderedAscending else { //左操作数小于右操作数，需要升级
                return
            }
            
            ///每个新版本提示一次
            guard KLMGetUserDefault(newVersion) == nil else { return }
            KLMSetUserDefault(newVersion, newVersion)
            
            ///弹出提示框
            let vc = UIAlertController.init(title: LANGLOC("checkUpdate"), message: newVersion, preferredStyle: .alert)
            vc.addAction(UIAlertAction.init(title: LANGLOC("Update"), style: .default, handler: { action in
                
                ///跳转到appleStore
                let url: String = "http://itunes.apple.com/app/id\(AppleStoreID)?mt=8"
                if UIApplication.shared.canOpenURL(URL.init(string: url)!) {
                    UIApplication.shared.open(URL.init(string: url)!, options: [:]) { _ in
                        
                    }
                }
            }))
            vc.addAction(UIAlertAction.init(title: LANGLOC("cancel"), style: .cancel, handler: nil))
            self.present(vc, animated: true, completion: nil)
            
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
    
    
    @IBAction func trackLights(_ sender: Any) {
        
        deviceType = .deviceTypeLight
        setupData()
    }
    
    @IBAction func controller(_ sender: Any) {
        deviceType = .deviceTypeController
        setupData()
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
            if model.isOnline == false {
                model.isOnline = true
                self.collectionView.reloadData()
            }
            if apptype == .test {

                let vc = KLMTestSectionTableViewController()
                self.navigationController?.pushViewController(vc, animated: true)

                return
            }
            
            let vc = KLMDeviceEditViewController()
            self.navigationController?.pushViewController(vc, animated: true)
            
        } failure: {
            if model.isOnline == true {
                MeshNetworkManager.bearer.close()
                MeshNetworkManager.bearer.open()
                model.isOnline = false
                self.collectionView.reloadData()
            }
        }
    }
    
    /// 长按删除
    /// - Parameter model: 节点
    func longPress(model: Node) {
        
        if KLMMesh.isCanEditMesh() == false {
            return
        }
        
        //弹出提示框
        let warnAlert = UIAlertController(title: LANGLOC("deleteDevice"),
                                      message: LANGLOC("Please make sure the device can not be connected with APP, otherwise use 'Settings reset'"),
                                      preferredStyle: .alert)
        let warnresetAction = UIAlertAction(title: LANGLOC("Remove"), style: .default) { _ in
            
            ///连接节点
            SVProgressHUD.show()
            KLMConnectManager.shared.connectToNode(node: model) { [weak self] in
                guard let self = self else { return }
                
                //连接上，重置设备。
                KLMSmartNode.sharedInstacnce.delegate = self
                KLMSmartNode.sharedInstacnce.resetNode(node: model)
                
            } failure: {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                //连接不上，直接删除设备
                MeshNetworkManager.instance.meshNetwork!.remove(node: model)
                if KLMMesh.save() {
                    //删除成功
                    self.setupData()
                }
            }
            
        }
        let warncancelAction = UIAlertAction(title: LANGLOC("cancel"), style: .cancel)
        warnAlert.addAction(warnresetAction)
        warnAlert.addAction(warncancelAction)
        self.present(warnAlert, animated: true)
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
            if node.isOnline == false {
                node.isOnline = true
                self.collectionView.reloadData()
            }
            
            if node.isController {
                
                let vc = KLMControllerSettingViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                return
            }
            if apptype == .test {

                let vc = KLMTestSectionTableViewController()
                self.navigationController?.pushViewController(vc, animated: true)

                return
            }

            let vc = KLMLightSettingController()
            self.navigationController?.pushViewController(vc, animated: true)

        } failure: {
            if node.isOnline == true {
                MeshNetworkManager.bearer.close()
                MeshNetworkManager.bearer.open()
                node.isOnline = false
                self.collectionView.reloadData()
            }
        }
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

extension KLMUnNameListViewController: KLMSmartNodeDelegate {
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode) {
        
        SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
        ///提交数据到服务器
        if KLMMesh.save() {
            self.setupData()
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        
        KLMShowError(error)
    }
}

extension KLMUnNameListViewController: GattDelegate {
     
    func bearerDidOpen(_ bearer: Bearer) {
        ///连接上一个设备，然后查询其他设备是否在线
        ///不加延时没效果，不知道具体原因
        DispatchQueue.main.asyncAfter(deadline: 1) {
            KLMSmartGroup.sharedInstacnce.checkAllNodesOnline()
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        KLMLog("首页设备一个都没连接")
        ///一个都没连
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            notConfiguredNodes.forEach({$0.isOnline = false})
            self.collectionView.reloadData()
        }
    }
    
    func bearerDidDiscover(_ bearer: Bearer) {
        ///判断是否已经连接一个，有可能设备只能一个人直连，如果发现设备就认为是在线，就会出现误判
        if MeshNetworkManager.bearer.isOpen == false {
            return
        }
        
//        DispatchQueue.main.asyncAfter(deadline: 3) { ///间隔一点时间，因为发现设备还需要一点时间才能发消息，避免显示在线绿点，但无法发消息
            if let bearer = bearer as? GattBearer {
                if let network = MeshNetworkManager.instance.meshNetwork {

                    let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
                    if let node = notConfiguredNodes.first(where: {$0.nodeuuidString == bearer.nodeUUID}) {
                        if node.isOnline == false {
                            node.isOnline = true
                            self.collectionView.reloadData()
                        }
                        KLMLog("发现的设备：\(node.nodeName)")
                    }
                }
            }
//        }
    }
}

extension KLMUnNameListViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        if let network = MeshNetworkManager.instance.meshNetwork {
    
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            if let node = notConfiguredNodes.first(where: {$0.unicastAddress == source}) {
                if node.isOnline == false {
                    node.isOnline = true
                    self.collectionView.reloadData()
                }
                KLMLog("连接的设备：\(node.nodeName)")
            }
        }
    }
}
