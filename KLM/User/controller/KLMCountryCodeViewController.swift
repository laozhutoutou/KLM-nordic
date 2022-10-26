//
//  KLMCountryCodeViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/8.
//

import UIKit

class KLMCountryCodeViewController: UIViewController {
    
    /// 选中国家后的闭包回调
    public var backCountryCode: ((String, String) -> Void)?
    
    @IBOutlet weak var tableView: UITableView!
    private var searchController: UISearchController?
    ///数据源
    private var sortedNameDict: [String: Any]?
    /// 筛选出后的结果array
    private var results: [Any] = Array()
    private var indexArray: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Region")
        navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(pushBack)) as? [UIBarButtonItem]
        
        setupUI()
    }
    
    private func setupUI() {
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = "Search"
        tableView.tableHeaderView = searchController?.searchBar
        
        /// 从plist文件中获取数据并存储
        let sortedName = Bundle.isChineseLanguage() ? "sortedNameCH" : "sortedNameEN"
        let path = Bundle.main.path(forResource: sortedName, ofType: "plist")
        sortedNameDict = NSDictionary(contentsOfFile: path ?? "") as? [String: Any]
        indexArray = Array(sortedNameDict!.keys).sorted(by: {$0 < $1})
    }
    /// 从存储数据中获取每条的国家+区号String
    private func showCodeStringIndex(indexPath: NSIndexPath) -> String {
        var showCodeString: String = ""
        if searchController!.isActive {
            if results.count > indexPath.row {
                showCodeString = results[indexPath.row] as? String ?? ""
            }
        } else {
            if indexArray!.count > indexPath.section {
                let sectionArray: [String] = sortedNameDict?[indexArray?[indexPath.section] ?? ""] as? [String] ?? [""]
                if sectionArray.count > indexPath.row {
                    showCodeString = sectionArray[indexPath.row]
                }
            }
        }
        return showCodeString
    }
    
    private func selectCodeIndex(indexPath: IndexPath) {
        let originText = self.showCodeStringIndex(indexPath: indexPath as NSIndexPath)
        let array = originText.components(separatedBy: "+")
        let countryName = array.first?.trimmingCharacters(in: CharacterSet.whitespaces)
        let code = array.last
        KLMLog("选择的国家\(countryName)--\(code)")
        if self.backCountryCode != nil {
            self.backCountryCode!(countryName ?? "", code ?? "")
        }
        searchController?.isActive = false
        searchController?.searchBar.resignFirstResponder()
        dismiss(animated: true)
    }
    
    @objc func pushBack() {
        
        dismiss(animated: true)
    }
}

extension KLMCountryCodeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if (searchController!.isActive) {
            return 1
        } else {
            return sortedNameDict?.keys.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController!.isActive {
            return results.count
        } else {
            if indexArray!.count > section {
                let array: [String] = sortedNameDict?[indexArray![section]] as? [String] ?? [""]
                return array.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        cell.leftTitle = self.showCodeStringIndex(indexPath: indexPath as NSIndexPath)
        return cell
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return indexArray
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return searchController!.isActive ? 0 : 30
    }
    
    /// 右侧的筛选sectionTitle
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if ((indexArray?.count) != nil) && indexArray!.count > section {
            return indexArray?[section]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.selectCodeIndex(indexPath: indexPath)
    }
}

extension KLMCountryCodeViewController: UISearchResultsUpdating {
    /// searchResults代理方法，将搜索到的内容加入resultArray 赋给tableView
    func updateSearchResults(for searchController: UISearchController) {
        if !results.isEmpty {
            results.removeAll()
        }
        let inputText = searchController.searchBar.text
        let array: [[String]] = Array(sortedNameDict!.values) as? [[String]] ?? [[""]]
        for obj in array {
            for obj in obj {
                if obj.contains(inputText ?? "") {
                    self.results.append(obj)
                }
            }
        }
        tableView.reloadData()
    }
}
