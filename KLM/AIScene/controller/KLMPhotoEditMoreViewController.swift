//
//  KLMPhotoEditMoreViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/5/12.
//

import UIKit

typealias EnhanceBlock = (_ enhan: RGBEnhance) -> Void
typealias sureBlock = () -> Void
typealias cancelBlock = () -> Void

class KLMPhotoEditMoreViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var RBgView: UIView!
    @IBOutlet weak var GBgView: UIView!
    @IBOutlet weak var BBgView: UIView!
    
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryLab: UILabel!
    
    ///大分类
    var categoryList: [KLMType] = [KLMType]()
    var selectCategory: KLMType?
    //果蔬子类
    var grocerySubTypes: [KLMType] = [KLMType]()
    var categoryPopView: YBPopupMenu?
    var allTypes: [KLMType] = [KLMType]()
    
    var RSlider: KLMSlider!
    var GSlider: KLMSlider!
    var BSlider: KLMSlider!
    
    ///rgb 单路
    var enhance: RGBEnhance = RGBEnhance()
    var sure: sureBlock?
    var cancel: cancelBlock?
    var enhanceBlock: EnhanceBlock?
    
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        
        setupData()
    }
    
    private func setUI() {
        
        cancelBtn.layer.cornerRadius = cancelBtn.height/2
        confirmBtn.layer.cornerRadius = cancelBtn.height/2
        cancelBtn.backgroundColor = appMainThemeColor
        confirmBtn.backgroundColor = appMainThemeColor
        
        //R滑条
        let viewLeft: CGFloat = 10
        let sliderWidth = KLMScreenW - viewLeft * 2
        let RRSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: RBgView.height), minValue: 0, maxValue: 100, step: 2)
        RRSlider.getValueTitle = { value in
            return String(format: "%ld%%", Int(value))
        }
        
        RRSlider.delegate = self
        self.RSlider = RRSlider
        RBgView.addSubview(RRSlider)
        
        //G滑条
        let GGSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: RBgView.height), minValue: 0, maxValue: 100, step: 2)
        GGSlider.getValueTitle = { value in
            return String(format: "%ld%%", Int(value))
        }
        
        GGSlider.delegate = self
        self.GSlider = GGSlider
        GBgView.addSubview(GGSlider)
        
        //B滑条
        let BBSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: RBgView.height), minValue: 0, maxValue: 100, step: 2)
        BBSlider.getValueTitle = { value in
            return String(format: "%ld%%", Int(value))
        }
        
        BBSlider.delegate = self
        self.BSlider = BBSlider
        BBgView.addSubview(BBSlider)
        
        let str: String = Bundle.main.path(forResource: "OccasionPlist", ofType: "plist")!
        let occations: NSArray = try! NSArray.init(contentsOf: URL.init(fileURLWithPath: str), error: ())
        categoryList = KLMTool.jsonToModel(type: KLMType.self, array: occations as! [[String : Any]])!
        
        let str1: String = Bundle.main.path(forResource: "GroceriesPlist", ofType: "plist")!
        let groceries: NSArray = try! NSArray.init(contentsOf: URL.init(fileURLWithPath: str1), error: ())
        grocerySubTypes = KLMTool.jsonToModel(type: KLMType.self, array: groceries as! [[String : Any]])!
        
        allTypes = categoryList + grocerySubTypes
    }
    
    private func setupData() {
        
        RSlider.currentValue = Float(enhance.RR)
        GSlider.currentValue = Float(enhance.GG)
        BSlider.currentValue = Float(enhance.BB)
        
        let title: String = allTypes.first(where: {$0.num == enhance.classification})!.title
        categoryLab.text = LANGLOC(title)
    }
    
    
    @IBAction func resetClick(_ sender: Any) {
        
        if let cancel = self.cancel {
            cancel()
        }
        navigationController?.popViewController(animated: true)
    }
    
    //确定
    @IBAction func bgClick(_ sender: Any) {
        
        if let sure = self.sure {
            sure()
        }
        navigationController?.popViewController(animated: true)
        
    }
    
    private func sendData() {
        
        if let enhan = self.enhanceBlock {
            enhan(enhance)
        }
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
    
}

extension KLMPhotoEditMoreViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        switch slider {
        case RSlider:
            enhance.RR = Int(value)
        case GSlider:
            enhance.GG = Int(value)
        case BSlider:
            enhance.BB = Int(value)
        default:
            break
        }
        
        sendData()
    }
}

extension KLMPhotoEditMoreViewController: YBPopupMenuDelegate {
    
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
            enhance.classification = selectCategory!.num
            sendData()
            
        } else { //果蔬二级菜单
            
            categoryPopView?.dismiss()
            selectCategory = grocerySubTypes[index]
            enhance.classification = selectCategory!.num
            sendData()
        }
        
        categoryLab.text = LANGLOC(selectCategory!.title)
        KLMLog("selectCategory = \(selectCategory)")
    }
}

class RGBEnhance {
    
    var RR: Int = 0
    var GG: Int = 0
    var BB: Int = 0
    var classification: Int = 2
}

