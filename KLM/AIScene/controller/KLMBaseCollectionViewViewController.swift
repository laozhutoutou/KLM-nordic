//
//  KLMBaseCollectionViewViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/19.
//

import UIKit
import nRFMeshProvision

typealias AddDeviceBlock = () -> Void
typealias RefreshDataBlock = () -> Void

class KLMBaseCollectionViewViewController: UIViewController {
    
    var addDevice: AddDeviceBlock?
    var refresh: RefreshDataBlock?
    
    lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
        let contentHeight = KLMScreenH - KLM_TopHeight - tabTopHeight - KLM_TabbarHeight
        let collectionView = UICollectionView.init(frame: CGRect.init(x: 0, y: 0, width: KLMScreenW, height: contentHeight), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.emptyDataSetDelegate = self
        collectionView.emptyDataSetSource = self
        collectionView.backgroundColor = appBackGroupColor
        collectionView.showsVerticalScrollIndicator = false
        ///内容少时，允许滑动
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    //设备数据源
    var nodes: [Node] = [Node]()
    
    private var collectionCanScroll: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        
        self.collectionView.register(UINib(nibName: String(describing: KLMAINameListCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: KLMAINameListCell.self))
        
        NotificationCenter.default.addObserver(self, selector: #selector(CollectionCanScroll), name: NSNotification.Name("collectionCanScroll"), object: nil)
    }
    
    @objc private func CollectionCanScroll() {
        collectionCanScroll = true
    }
    
    @objc private func newDevice() {
        
        if let addDevice = addDevice {
            addDevice()
        }
    }
    
    private func setupData() {
        
        if let refresh = refresh {
            refresh()
        }
    }
    
    func reloadData() {
        
        collectionView.reloadData()
    }
    
    func reloadData(node: Node) {
        
        if let index = nodes.firstIndex(where: {$0.uuid == node.uuid}) {
            let indexPath = IndexPath.init(item: index, section: 0)
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

extension KLMBaseCollectionViewViewController: UICollectionViewDelegate, UICollectionViewDataSource,  UICollectionViewDelegateFlowLayout {
    
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
                (UIApplication.shared.delegate as! AppDelegate).getMainController()?.navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if apptype == .test {

                let vc = KLMTestSectionTableViewController()
                (UIApplication.shared.delegate as! AppDelegate).getMainController()?.navigationController?.pushViewController(vc, animated: true)

                return
            }

            let vc = KLMLightSettingController()
            (UIApplication.shared.delegate as! AppDelegate).getMainController()?.navigationController?.pushViewController(vc, animated: true)

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

extension KLMBaseCollectionViewViewController: KLMAINameListCellDelegate {
    
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
            
            if model.isController {
                
                let vc = KLMControllerSettingViewController()
                (UIApplication.shared.delegate as! AppDelegate).getMainController()?.navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if apptype == .test {

                let vc = KLMTestSectionTableViewController()
                (UIApplication.shared.delegate as! AppDelegate).getMainController()?.navigationController?.pushViewController(vc, animated: true)

                return
            }
            
            let vc = KLMDeviceEditViewController()
            (UIApplication.shared.delegate as! AppDelegate).getMainController()?.navigationController?.pushViewController(vc, animated: true)
            
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
        let warnAlert = UIAlertController(title: LANGLOC("Remove Device"),
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
        let warncancelAction = UIAlertAction(title: LANGLOC("Cancel"), style: .cancel)
        warnAlert.addAction(warnresetAction)
        warnAlert.addAction(warncancelAction)
        self.present(warnAlert, animated: true)
    }
}

extension KLMBaseCollectionViewViewController: KLMSmartNodeDelegate {
    
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

extension KLMBaseCollectionViewViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {

        return true
    }

    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {

        let contentView = UIView()

        let addBtn = UIButton()
        addBtn.backgroundColor = appMainThemeColor
        addBtn.setTitleColor(.white, for: .normal)
        addBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        addBtn.setTitle(LANGLOC("Add new device"), for: .normal)
        addBtn.addTarget(self, action: #selector(newDevice), for: .touchUpInside)
        addBtn.layer.cornerRadius = 20
        contentView.addSubview(addBtn)
        addBtn.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(140)
            make.height.equalTo(40)
        }

        let titleLab = UILabel()
        titleLab.text = LANGLOC("No devices")
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

extension KLMBaseCollectionViewViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        if scrollView == collectionView {
            if collectionCanScroll == true {
                if scrollView.contentOffset.y <= 0 {
                   collectionCanScroll = false
                    scrollView.contentOffset = CGPoint.zero
                    // 通知ScrollView改变CanScroll的状态
                    NotificationCenter.default.post(name: NSNotification.Name("ScrollViewCanScroll"), object: nil, userInfo: nil)
               }
            } else {
                scrollView.contentOffset = CGPoint.zero

            }
        }
    }
}
