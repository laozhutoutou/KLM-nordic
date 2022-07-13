//
//  KLMDeviceNameAndTypePopViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/1.
//

import UIKit

typealias NameAndTypeBlock = (_ name: String, _ type: Int) -> Void

class KLMDeviceNameAndTypePopViewController: UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var categoryLab: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var categoryView: UIView!
    
    var nameAndTypeBlock: NameAndTypeBlock?
    var cancelBlock: (() -> Void)?
    var categoryList: [KLMType] = [KLMType]()
    var selectCategory: KLMType?
    var grocerySubTypes: [KLMType] = [KLMType]()
    var categoryPopView: YBPopupMenu?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.height))
        textField.leftView  = leftView
        textField.leftViewMode = .always
        textField.layer.cornerRadius = 4
        
        contentView.layer.cornerRadius = 8
        
        let str: String = Bundle.main.path(forResource: "OccasionPlist", ofType: "plist")!
        let occations: NSArray = try! NSArray.init(contentsOf: URL.init(fileURLWithPath: str), error: ())
        categoryList = KLMTool.jsonToModel(type: KLMType.self, array: occations as! [[String : Any]])!
        
        let str1: String = Bundle.main.path(forResource: "GroceriesPlist", ofType: "plist")!
        let groceries: NSArray = try! NSArray.init(contentsOf: URL.init(fileURLWithPath: str1), error: ())
        grocerySubTypes = KLMTool.jsonToModel(type: KLMType.self, array: groceries as! [[String : Any]])!
        
    }
    
    @IBAction func sure(_ sender: Any) {

        guard let text = KLMTool.isEmptyString(string: textField.text) else {
            SVProgressHUD.showInfo(withStatus: textField.placeholder)
            return
        }
        
        guard let cate = selectCategory  else {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please select use occasion"))
            return
        }

        if let nameB = nameAndTypeBlock {
            nameB(text, cate.num)
        }

        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapCategory(_ sender: UITapGestureRecognizer) {
        
        let menuViewrect: CGRect = categoryView.convert(categoryView.bounds, to: KLMKeyWindow)
        let point: CGPoint = CGPoint.init(x: menuViewrect.origin.x, y: menuViewrect.origin.y + menuViewrect.size.height)
        var titles: [String] = [String]()
        for model in categoryList {
            titles.append(LANGLOC(model.title))
        }
        YBPopupMenu.show(at: point, titles: titles, icons: nil, menuWidth: 120) { popupMenu in
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
    
    @IBAction func cancel(_ sender: Any) {
        if let cancel = cancelBlock {
            cancel()
        }
        
        dismiss(animated: true, completion: nil)
    }
}

extension KLMDeviceNameAndTypePopViewController: YBPopupMenuDelegate {
    
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
                    popupMenu?.minSpace = menuViewrect.origin.x + 120
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
