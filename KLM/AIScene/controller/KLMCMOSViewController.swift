//
//  KLMCMOSViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/6/10.
//

import UIKit

class KLMCMOSViewController: UIViewController {
    
    
    @IBOutlet weak var secondBtn: UIButton!
    @IBOutlet weak var mimuteBtn: UIButton!
    
    @IBOutlet weak var secondView: UIView!
    @IBOutlet weak var timeBgView: UIView!
    var timeSlider: KLMSlider!
    
    @IBOutlet weak var mimuteView: UIView!
    @IBOutlet weak var minuteTimeBgView: UIView!
    var mimuteSlider: KLMSlider!
    
    //分类
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryLab: UILabel!
    ///大分类
    var categoryList: [KLMType] = [KLMType]()
    var selectCategory: KLMType?
    //果蔬子类
    var grocerySubTypes: [KLMType] = [KLMType]()
    var categoryPopView: YBPopupMenu?
    var allTypes: [KLMType] = [KLMType]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
    }
    
    private func setupUI() {
        
        navigationItem.title = LANGLOC("Interval & occasion change")
        
        //滑条
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
        let timeSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: timeBgView.height), minValue: 5, maxValue: 60, step: 1)
        timeSlider.getValueTitle = { value in
            
            return String(format: "%lds", Int(value))
        }
        timeSlider.currentValue = 5
        timeSlider.delegate = self
        self.timeSlider = timeSlider
        timeBgView.addSubview(timeSlider)
        
        let mimuteSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: minuteTimeBgView.height), minValue: 10, maxValue: 120, step: 2)
        mimuteSlider.getValueTitle = { value in
            
            return String(format: "%ldm", Int(value))
        }
        mimuteSlider.currentValue = 10
        mimuteSlider.delegate = self
        self.mimuteSlider = mimuteSlider
        minuteTimeBgView.addSubview(mimuteSlider)
        
        //切换按钮
        secondBtn.setTitleColor(.white, for: .selected)
        mimuteBtn.setTitleColor(.white, for: .selected)
        secondBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        mimuteBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        
        mimuteBtn.isSelected = true
        secondView.isHidden = true
        
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
        
        //读取数据
        SVProgressHUD.show()
        let parame = parameModel(dp: .category)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)

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
    
    @IBAction func secondClick(_ sender: UIButton) {
        secondBtn.isSelected = true
        mimuteBtn.isSelected = false
        secondView.isHidden = false
        mimuteView.isHidden = true
    }
    
    @IBAction func minuteClick(_ sender: UIButton) {
        mimuteBtn.isSelected = true
        secondBtn.isSelected = false
        mimuteView.isHidden = false
        secondView.isHidden = true
    }
    
    private func sendData() {
        
        //发送分类指令
        SVProgressHUD.show()
        let parame = parameModel(dp: .category, value: selectCategory!.num)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMCMOSViewController: YBPopupMenuDelegate {
    
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
            sendData()
        } else { //果蔬二级菜单
            
            categoryPopView?.dismiss()
            selectCategory = grocerySubTypes[index]
            sendData()
        }
        
        categoryLab.text = LANGLOC(selectCategory!.title)
        KLMLog("selectCategory = \(selectCategory)")
    }
}

extension KLMCMOSViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        var vv = Int(value)
        if slider == mimuteSlider {
            
            vv = vv * 60
        }
        let parame = parameModel(dp: .colorTest, value: vv.decimalTo4Hexadecimal())
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMCMOSViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? Int, message?.dp == .category {
            SVProgressHUD.dismiss()
            let title: String = allTypes.first(where: {$0.num == value})!.title
            categoryLab.text = LANGLOC(title)
            if selectCategory != nil {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            }
        }
        
        if message?.dp ==  .colorTest{
            
            //成功
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
