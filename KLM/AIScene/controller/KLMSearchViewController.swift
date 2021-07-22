//
//  KLMSearchViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit
import nRFMeshProvision

class KLMSearchViewController: UIViewController, UICollectionViewDelegateFlowLayout {
    
    lazy var historyView: KLMSearchHistoryView = {
        let view = KLMSearchHistoryView.historyView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        view.delegate = self
        return view
    }()
    
    lazy var collectionView: UICollectionView = {
        let layOut: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layOut.minimumLineSpacing = 15
        layOut.minimumInteritemSpacing = 15
        let width: CGFloat = (KLMScreenW - 15 * 3) / 2
        layOut.itemSize = CGSize(width: width, height: 250)
        layOut.sectionInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        let colView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: KLMScreenH - KLM_TopHeight), collectionViewLayout: layOut)
        colView.backgroundColor = appBackGroupColor
        colView.delegate = self
        colView.dataSource = self
        return colView
    }()
    
    
    lazy var searchBar: CMSearchBar = {
        let searchBar = CMSearchBar(frame: CGRect(x: 15, y: KLM_StatusBarHeight + 10, width: KLMScreenW - 16 - 60, height: 28))
        searchBar.placeholder = LANGLOC("searchDeviceName")
        searchBar.backgroundColor = rgb(246, 246, 246)
        searchBar.layer.cornerRadius = 28 / 2
        searchBar.showsCancelButton = false
        searchBar.delegate = self
        return searchBar
    }()
    
    //数据源
    lazy var searchLists: [Node] = {
        let  searchLists = [Node]()
        return searchLists
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.searchBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.searchBar.isHidden = true
//        self.searchBar.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = appBackGroupColor
        
        view.addSubview(self.historyView)
        self.historyView.reloadData()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("cancel"), target: self, action: #selector(cancel))
        
        navigationController?.view.addSubview(self.searchBar)
        self.searchBar.becomeFirstResponder()
        
        self.collectionView.register(UINib(nibName: String(describing: KLMAINameListCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: KLMAINameListCell.self))
        self.collectionView.isHidden = true
        self.view.addSubview(self.collectionView)

    }

    @objc func cancel() {
        
        dismiss(animated: true, completion: nil)
    }
    
    func searchStart() {
        
        if self.searchBar.text!.isEmpty {
            
            self.historyView.isHidden = false
            self.collectionView.isHidden = true
        }else {
            
            self.historyView.isHidden = true
            self.collectionView.isHidden = false
        }
        
        self.searchLists.removeAll()
        let network = MeshNetworkManager.instance.meshNetwork!
        let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner })
        let array = ZYPinYinSearch.search(withOriginalArray: notConfiguredNodes, andSearchText: self.searchBar.text, andSearchByPropertyName: "name")
        self.searchLists = array! as! [Node]
        self.collectionView.reloadData()
    }
}

extension KLMSearchViewController: CMSearchBarDelegate {
    
    func searchBar(_ searchBar: CMSearchBar, textDidChange searchText: String) {
        
        searchStart()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: CMSearchBar) {
        
        //存储历史记录
        let (err, str) = isEmptyString(text: searchBar.text)
        if err == false {
            
            var list:[String] = KLMHomeManager.getHistoryLists()
            //过滤重复记录
            for string in list {
                if string == str {
                    return
                }
            }
            list.insert(str, at: 0)
            KLMHomeManager.cacheHistoryLists(list: list)
            self.historyView.reloadData()
            
        }
        
    }
}

extension KLMSearchViewController: KLMSearchHistoryViewDelegate {
    
    func KLMSearchHistoryViewDidSelectHistory(text: String) {
        
        self.searchBar.text = text
        self.searchStart()
    }

}
 
extension KLMSearchViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.searchLists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let deviceModel:  Node = self.searchLists[indexPath.item]
        let cell: KLMAINameListCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: KLMAINameListCell.self), for: indexPath) as! KLMAINameListCell
        cell.model = deviceModel
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
//        let deviceModel:  TuyaSmartDeviceModel = self.searchLists[indexPath.item]
        //记录当前设备
//        KLMHomeManager.sharedInstacnce.smartNode = TuyaSmartDevice.init(deviceId: deviceModel.devId)
        
        
    }
}






