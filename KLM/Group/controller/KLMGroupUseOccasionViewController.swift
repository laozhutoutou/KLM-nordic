//
//  KLMGroupUseOccasionViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/23.
//

import UIKit

class KLMGroupUseOccasionViewController: UIViewController, Editable {
    
    //分类
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryLab: UILabel!
    
    @IBOutlet weak var confirmBtn: UIButton!
    
    ///大分类
    var categoryList: [KLMType] = [KLMType]()
    var selectCategory: KLMType?
    //果蔬子类
    var grocerySubTypes: [KLMType] = [KLMType]()
    var categoryPopView: YBPopupMenu?
    var allTypes: [KLMType] = [KLMType]()
    
    ///分组数据
    var groupData: GroupData = GroupData()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        setupData()
        
        showEmptyView()
    }

    private func setupUI() {
        
        navigationItem.title = LANGLOC("Occasion change")
        confirmBtn.layer.cornerRadius = 8
        confirmBtn.backgroundColor = appMainThemeColor
        
        //分类
        let str: String = Bundle.main.path(forResource: "OccasionPlist", ofType: "plist")!
        let occations: NSArray = try! NSArray.init(contentsOf: URL.init(fileURLWithPath: str), error: ())
        categoryList = KLMTool.jsonToModel(type: KLMType.self, array: occations as! [[String : Any]])!
        
        let str1: String = Bundle.main.path(forResource: "GroceriesPlist", ofType: "plist")!
        let groceries: NSArray = try! NSArray.init(contentsOf: URL.init(fileURLWithPath: str1), error: ())
        grocerySubTypes = KLMTool.jsonToModel(type: KLMType.self, array: groceries as! [[String : Any]])!
        allTypes = categoryList + grocerySubTypes
        
    }
    
    private func setupData() {

        let address = Int(KLMHomeManager.currentGroup.address.address)
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        KLMService.selectGroup(groupId: address) { response in
            SVProgressHUD.dismiss()
            guard let model = response as? GroupData else { return  }
            self.groupData = model
            
            self.updateUI()
            self.hideEmptyView()
        } failure: { error in
            self.updateUI()
            self.hideEmptyView()
            SVProgressHUD.dismiss()
        }
    }
    
    private func updateUI() {
        
        let title: String = allTypes.first(where: {$0.num == self.groupData.useOccasion})!.title
        selectCategory = KLMType.init(title: title, num: self.groupData.useOccasion)
        categoryLab.text = LANGLOC(title)
    }
    
    @IBAction func tapCategory(_ sender: UITapGestureRecognizer) {
        
        let menuViewrect: CGRect = categoryView.convert(categoryView.bounds, to: KLMKeyWindow)
        let point: CGPoint = CGPoint.init(x: menuViewrect.origin.x, y: menuViewrect.origin.y + menuViewrect.size.height)
        var titles: [String] = [String]()
        for model in categoryList {
            titles.append(LANGLOC(model.title))
        }
        YBPopupMenu.show(at: point, titles: titles, icons: nil, menuWidth: 150) { popupMenu in
            popupMenu?.priorityDirection = .none
            popupMenu?.arrowHeight = 0
            popupMenu?.minSpace = menuViewrect.origin.x
            popupMenu?.dismissOnSelected = false
            popupMenu?.isShadowShowing = false
            popupMenu?.delegate = self
            popupMenu?.cornerRadius = 0
            popupMenu?.tag = 100
            self.categoryPopView = popupMenu
        }
    }
    
    private func sendData() {
        
        let address = Int(KLMHomeManager.currentGroup.address.address)
        KLMService.updateGroup(groupId: address, groupData: self.groupData) { response in
            self.navigationController?.popViewController(animated: true)
        } failure: { error in
            
        }
    }
    
    @IBAction func confirmClick(_ sender: Any) {
        
        let parame = parameModel(dp: .category, value: selectCategory!.num)
        KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in 
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            
            self.groupData.useOccasion = self.selectCategory!.num
            self.sendData()
            
        } failure: { error in
            KLMShowError(error)
        }
    }
}

extension KLMGroupUseOccasionViewController: YBPopupMenuDelegate {
    
    func ybPopupMenu(_ ybPopupMenu: YBPopupMenu!, didSelectedAt index: Int) {
        
        if ybPopupMenu.tag == 100 {
            
            if index == 0 { //弹出二级菜单
                
                let menuViewrect: CGRect = categoryView.convert(categoryView.bounds, to: KLMKeyWindow)
                let point: CGPoint = CGPoint.init(x: menuViewrect.origin.x, y: menuViewrect.origin.y + menuViewrect.size.height)
                var titles: [String] = [String]()
                for model in grocerySubTypes {
                    titles.append(LANGLOC(model.title))
                }
                YBPopupMenu.show(at: point, titles: titles, icons: nil, menuWidth: 120) { popupMenu in
                    popupMenu?.priorityDirection = .none
                    popupMenu?.arrowHeight = 0
                    popupMenu?.minSpace = menuViewrect.origin.x + 150
                    popupMenu?.isShadowShowing = false
                    popupMenu?.delegate = self
                    popupMenu?.cornerRadius = 0
                    popupMenu?.tag = 10
                }
                
                return
            }
            
            ybPopupMenu.dismiss()
            selectCategory = categoryList[index]

        } else { //果蔬二级菜单
            
            categoryPopView?.dismiss()
            selectCategory = grocerySubTypes[index]

        }
        
        categoryLab.text = LANGLOC(selectCategory!.title)
        KLMLog("selectCategory = \(selectCategory)")
    }
}
