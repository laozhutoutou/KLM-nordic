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
    
    //设备数据源
    var nodes: [Node] = [Node]()
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
    }

    @objc func setupData(){
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            
            let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner && $0.name == nil})
            
            self.nodes.removeAll()
            self.nodes = notConfiguredNodes
            self.collectionView.reloadData()
            self.collectionView.mj_header?.endRefreshing()
        }
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
        
        let itemWidth: CGFloat = (KLMScreenW - 15*3) / 2
        let itemHeight: CGFloat = 150.0
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
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



