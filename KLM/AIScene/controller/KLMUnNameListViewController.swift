//
//  KLMUnNameListViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit
import nRFMeshProvision

class KLMUnNameListViewController: UIViewController{
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var searchBar: UIView = {
        let searchBar = UIView.init(frame: CGRect(x: 16, y: KLM_StatusBarHeight + 7, width: KLMScreenW - 15 - 65, height: 30))
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
    
    //设备数据源
    var nodes: [Node] = [Node]()
    
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
//        view.backgroundColor = appBackGroupColor
        collectionView.backgroundColor = appBackGroupColor
        
        navigationController?.view.addSubview(self.searchBar)
        
        self.collectionView.register(UINib(nibName: String(describing: KLMAINameListCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: KLMAINameListCell.self))
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceAddSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceNameUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setupData), name: .deviceReset, object: nil)
        
        setupData()
        
        //刷新
        let header = KLMRefreshHeader.init {[weak self] in
            guard let self = self else { return }
            self.setupData()
        }
        self.collectionView.mj_header = header
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(icon: "icon_new_scene", target: self, action: #selector(newDevice))
        
    }

    @objc func setupData(){
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner})
            
            self.nodes.removeAll()
            self.nodes = notConfiguredNodes
            self.collectionView.reloadData()
            self.collectionView.mj_header?.endRefreshing()
        }
    }
    
    @objc func tapSearch() {
        
        let vc = KLMSearchViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func newDevice() {
        
        let vc = KLMAddDeviceViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension KLMUnNameListViewController: KLMAINameListCellDelegate {
    
    func longPressItem(model: Node) {
        
        KLMHomeManager.sharedInstacnce.smartNode = model
        
        if !MeshNetworkManager.bearer.isOpen {
            SVProgressHUD.showError(withStatus: "Device Offline")
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
        
        let vc = KLMDeviceEditViewController()
        self.navigationController?.pushViewController(vc, animated: true)
        
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
            SVProgressHUD.showError(withStatus: "Device Offline")
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
        
        SVProgressHUD.showSuccess(withStatus: "please tap again")
        
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: Error?){
        
        KLMShowError(error)
    }
}



