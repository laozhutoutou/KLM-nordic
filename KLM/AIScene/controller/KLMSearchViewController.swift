//
//  KLMSearchViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit
import nRFMeshProvision

class KLMSearchViewController: UIViewController {
    
    lazy var historyView: KLMSearchHistoryView = {
        let view = KLMSearchHistoryView.historyView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        view.delegate = self
        return view
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView.init(frame: CGRect(x: 0, y: 0, width: self.view.width, height: KLMScreenH - KLM_TopHeight), style: .plain)
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
        tableView.backgroundColor = appBackGroupColor
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    lazy var searchBar: CMSearchBar = {
        let searchBar = CMSearchBar(frame: CGRect(x: 42, y: KLM_StatusBarHeight + 7, width: KLMScreenW - 42 - 17, height: 32))
        searchBar.placeholder = LANGLOC("searchDeviceName")
        searchBar.backgroundColor = rgb(247, 247, 247)
        searchBar.layer.cornerRadius = 32 / 2
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
        self.searchBar.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()

    }
    
    func setupUI() {
        
        self.view.backgroundColor = appBackGroupColor
        
        view.addSubview(self.historyView)
        self.historyView.reloadData()
        
        navigationController?.view.addSubview(self.searchBar)
        self.searchBar.becomeFirstResponder()
        
        self.tableView.isHidden = true
        self.view.addSubview(self.tableView)
        
        self.navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(pushBack)) as? [UIBarButtonItem]
    }
    
    @objc func pushBack() {
        
        dismiss(animated: true, completion: nil)
    }
    
    func searchStart() {
        
        if self.searchBar.text!.isEmpty {
            
            self.historyView.isHidden = false
            self.tableView.isHidden = true
        }else {
            
            self.historyView.isHidden = true
            self.tableView.isHidden = false
        }
        
        
        self.searchLists.removeAll()
        let network = MeshNetworkManager.instance.meshNetwork!
        let notConfiguredNodes = network.nodes.filter({ !$0.isConfigComplete && !$0.isProvisioner })
        self.searchLists = notConfiguredNodes.filter({
//            ($0.name?.contains(self.searchBar.text!))!
            ($0.name?.range(of: self.searchBar.text!, options: .caseInsensitive) != nil)
        })
        self.tableView.reloadData()
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

extension KLMSearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.searchLists.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let deviceModel:  Node = self.searchLists[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.leftImage = "img_scene_48"
        cell.leftTitle = deviceModel.name
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let deviceModel:  Node = self.searchLists[indexPath.row]
        
        KLMHomeManager.sharedInstacnce.smartNode = deviceModel
        
        if !MeshNetworkManager.bearer.isOpen {
            SVProgressHUD.showInfo(withStatus: "Connecting...")
            return
        }
        if !deviceModel.isCompositionDataReceived {
            //对于未composition的进行配置
            SVProgressHUD.show(withStatus: "Composition")
            SVProgressHUD.setDefaultMaskType(.black)
            
            KLMSIGMeshManager.sharedInstacnce.delegate = self
            KLMSIGMeshManager.sharedInstacnce.getCompositionData(node: deviceModel)
            return
        }
        
        let vc = KLMDeviceEditViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension KLMSearchViewController: KLMSIGMeshManagerDelegate {
        
    func sigMeshManager(_ manager: KLMSIGMeshManager, didActiveDevice device: Node) {
        
        SVProgressHUD.showSuccess(withStatus: "please tap again")
        
    }
    
    func sigMeshManager(_ manager: KLMSIGMeshManager, didFailToActiveDevice error: MessageError?){
        
        KLMShowError(error)
    }
}

 





