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

let tabTopHeight = 40.0

class KLMUnNameListViewController: UIViewController,  Editable{
    
    ///主视图
    @IBOutlet weak var scrollView: NestScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
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
    
    //家庭数据源
    var homes: [KLMHome.KLMHomeModel] = []
    private var canScroll: Bool = true
    
    @IBOutlet weak var trackLightBtn: UIButton!
    @IBOutlet weak var controllerBtn: UIButton!
    
    lazy var trackLightVc: KLMTrackLightsMainViewController = {
        let trackLightVc = KLMTrackLightsMainViewController()
        return trackLightVc
    }()
    
    lazy var controllerVc: KLMControllersMainViewController = {
        let controllerVc = KLMControllersMainViewController()
        return controllerVc
    }()
    ///水平滚动视图
    lazy var HScrollView: UIScrollView = {
        let HScrollView = UIScrollView.init()
        HScrollView.isPagingEnabled = true
        return HScrollView
    }()
    
    private var deviceType: DeviceType = .deviceTypeLight {
        didSet {
            trackLightBtn.isSelected = deviceType == .deviceTypeLight ? true : false
            controllerBtn.isSelected = deviceType == .deviceTypeLight ? false : true
            if deviceType == .deviceTypeLight {
                HScrollView.contentOffset(x: 0, y: 0)
            } else if deviceType == .deviceTypeController {
                HScrollView.contentOffset(x: KLMScreenW, y: 0)
            }
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
        
        ///左右滑动视图
        let contentHeight = KLMScreenH - KLM_TopHeight - tabTopHeight - KLM_TabbarHeight
        HScrollView.frame = CGRect.init(x: 0, y: 0, width: KLMScreenW, height: contentHeight)
        HScrollView.contentSize = CGSizeMake(KLMScreenW * 2, contentHeight)
        HScrollView.delegate = self
        HScrollView.showsHorizontalScrollIndicator = false
        contentView.addSubview(HScrollView)
        
        ///轨道灯
        trackLightVc.view.frame = CGRect.init(x: 0, y: 0, width: KLMScreenW, height: contentHeight)
        HScrollView.addSubview(trackLightVc.view)
        trackLightVc.addDevice = { [weak self] in
            guard let self = self else { return }
            self.newDevice()
        }
        trackLightVc.refresh = { [weak self] in
            guard let self = self else { return }
            self.setupData()
        }
        
        ///控制器
        controllerVc.view.frame = CGRect.init(x: KLMScreenW, y: 0, width: KLMScreenW, height: contentHeight)
        HScrollView.addSubview(controllerVc.view)
        controllerVc.addDevice = { [weak self] in
            guard let self = self else { return }
            self.newDevice()
        }
        controllerVc.refresh = { [weak self] in
            guard let self = self else { return }
            self.setupData()
        }
        
        contentViewHeight.constant = contentHeight
        
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
        self.scrollView.mj_header = header
        
        ///默认选择轨道灯
        deviceType = .deviceTypeLight
        
        NotificationCenter.default.addObserver(self, selector: #selector(ScrollViewCanScroll), name: NSNotification.Name("ScrollViewCanScroll"), object: nil)
        
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
        DispatchQueue.main.asyncAfter(deadline: 1) {
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

            KLMHttpShowError(error)
        }
    }

    @objc func setupData(){
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            ///所有设备
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            
            trackLightVc.nodes.removeAll()
            controllerVc.nodes.removeAll()
            trackLightVc.nodes = notConfiguredNodes.filter({ $0.isTracklight})
            controllerVc.nodes = notConfiguredNodes.filter({ $0.isController})
            reloadData()
        }
        
        self.scrollView.mj_header?.endRefreshing()
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
       
    }
    
    @IBAction func controller(_ sender: Any) {
        deviceType = .deviceTypeController

    }
    ///刷新页面 -- 全部
    private func reloadData() {
        
        trackLightVc.reloadData()
        controllerVc.reloadData()
    }
    
    ///刷新页面- 某一个
    private func reloadData(node: Node) {
        
        trackLightVc.reloadData(node: node)
        controllerVc.reloadData(node: node)
    }
    
    @objc private func ScrollViewCanScroll() {
        canScroll = true
    }
}

extension KLMUnNameListViewController: YBPopupMenuDelegate {
    
    func ybPopupMenu(_ ybPopupMenu: YBPopupMenu!, didSelectedAt index: Int) {
        
        let selectHome = self.homes[index]
        if let home = KLMMesh.loadHome(), selectHome.id == home.id {
            return
        }
        
        deviceType = .deviceTypeLight
        
        //取缓存数据
        if let localHome = KLMMesh.getHome(homeId: selectHome.id) {
            KLMMesh.saveHome(home: localHome)
        } else {
            KLMMesh.saveHome(home: selectHome)
        }
        self.initData()
    }
}
 
extension KLMUnNameListViewController: GattDelegate {
     
    func bearerDidOpen(_ bearer: Bearer) {
        
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        KLMLog("首页设备一个都没连接")
        ///一个都没连
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            notConfiguredNodes.forEach({$0.isOnline = false})
            reloadData()
        }
    }
    
    func bearerDidDiscover(_ bearer: Bearer) {
        
        DispatchQueue.main.asyncAfter(deadline: 3) { [self] in ///间隔一点时间，因为发现设备还需要一点时间才能发消息，避免显示在线绿点，但无法发消息
            if let bearer = bearer as? GattBearer {
                if let network = MeshNetworkManager.instance.meshNetwork {

                    let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
                    if let node = notConfiguredNodes.first(where: {$0.nodeuuidString == bearer.nodeUUID}) {
                        if node.isOnline == false {
                            node.isOnline = true
                            self.reloadData(node: node)
                        }
                    }
                }
            }
        }
    }
}

extension KLMUnNameListViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
         
        if scrollView == HScrollView {
            let offset = scrollView.contentOffset.x / KLMScreenW
            if offset == 0 {
                deviceType = .deviceTypeLight
            } else if offset == 1 {
                deviceType = .deviceTypeController
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {

            if canScroll  {
                
                if scrollView.contentOffset.y >= 0 {
                    scrollView.contentOffset = CGPoint.zero
                    canScroll = false
                    NotificationCenter.default.post(name: NSNotification.Name("collectionCanScroll"), object: nil, userInfo: nil)
                }

            } else  {
                
                scrollView.contentOffset = CGPoint.zero
                NotificationCenter.default.post(name: NSNotification.Name("collectionCanScroll"), object: nil, userInfo: nil)
                
                
            }
        }
    }
}
