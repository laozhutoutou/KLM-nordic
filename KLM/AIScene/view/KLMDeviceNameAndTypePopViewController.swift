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
    var category: Int?
    
    let categoryList: [String] = [LANGLOC("Groceries"), LANGLOC("Clothing"), LANGLOC("Plants"), LANGLOC("Others")]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.height))
        textField.leftView  = leftView
        textField.leftViewMode = .always
        textField.layer.cornerRadius = 4
        
        contentView.layer.cornerRadius = 8
    }
    
    @IBAction func sure(_ sender: Any) {
        
        guard let text = self.textField.text, text.isEmpty == false else {
            SVProgressHUD.showInfo(withStatus: self.textField.placeholder)
            return
        }
        
        ///去掉最后的空格
        let tt = text.trimmingCharacters(in: .whitespaces)
        if tt.isEmpty == true {
            SVProgressHUD.showInfo(withStatus: self.textField.placeholder)
            return
        }
        
        guard let cate = category  else {
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please select use occasion"))
            return
        }

        if let nameB = nameAndTypeBlock {
            nameB(tt, cate)
        }

        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapCategory(_ sender: UITapGestureRecognizer) {
        
        let menuViewrect: CGRect = categoryView.convert(categoryView.bounds, to: KLMKeyWindow)
        let point: CGPoint = CGPoint.init(x: menuViewrect.origin.x, y: menuViewrect.origin.y + menuViewrect.size.height)
        YBPopupMenu.show(at: point, titles: categoryList, icons: nil, menuWidth: 120) { popupMenu in
            popupMenu?.priorityDirection = .none
            popupMenu?.arrowHeight = 0
            popupMenu?.minSpace = menuViewrect.origin.x
            popupMenu?.dismissOnSelected = true
            popupMenu?.isShadowShowing = false
            popupMenu?.delegate = self
            popupMenu?.cornerRadius = 0
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
        
        category = index + 1
        let title = categoryList[index]
        categoryLab.text = title
        KLMLog("index = \(category), category = \(title)")
    }
}
