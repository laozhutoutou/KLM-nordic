//
//  KLMCMOSViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/6/10.
//

import UIKit
import RxSwift
import RxCocoa

class KLMCMOSViewController: UIViewController, Editable {
    
    @IBOutlet weak var secondBtn: UIButton!
    @IBOutlet weak var mimuteBtn: UIButton!
    //秒
    @IBOutlet weak var secondView: UIView!
    @IBOutlet weak var secondTimeBgView: UIView!
    var secondSlider: KLMSlider!
    
    //分
    @IBOutlet weak var mimuteView: UIView!
    @IBOutlet weak var minuteTimeBgView: UIView!
    var mimuteSlider: KLMSlider!
    
    //分类
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryLab: UILabel!
    
    @IBOutlet weak var confirmBtn: UIButton!
    
    @IBOutlet weak var timeINtervalS: UILabel!
    @IBOutlet weak var timeIntervalM: UILabel!
    
    @IBOutlet weak var useOccasionLab: UILabel!
    ///大分类
    var categoryList: [KLMType] = [KLMType]()
    var selectCategory: KLMType?
    //果蔬子类
    var grocerySubTypes: [KLMType] = [KLMType]()
    var categoryPopView: YBPopupMenu?
    var allTypes: [KLMType] = [KLMType]()
    
    var isTimeControl: Bool = false
    
    var currentTime: UInt16 = 0 {
        
        didSet {
            
            mimuteBtn.isSelected = Float(currentTime) > secondSlider.maxValue ? true : false
            secondBtn.isSelected = Float(currentTime) > secondSlider.maxValue ? false : true
            mimuteView.isHidden = Float(currentTime) > secondSlider.maxValue ? false : true
            secondView.isHidden = Float(currentTime) > secondSlider.maxValue ? true : false
            mimuteBtn.titleLabel?.font = Float(currentTime) > secondSlider.maxValue ? UIFont.boldSystemFont(ofSize: 18) : UIFont.systemFont(ofSize: 15)
            secondBtn.titleLabel?.font = Float(currentTime) > secondSlider.maxValue ? UIFont.systemFont(ofSize: 15) : UIFont.boldSystemFont(ofSize: 18)
            if Float(currentTime) > secondSlider.maxValue  { //分钟
                mimuteSlider.currentValue = Float(currentTime) / 60
            } else if currentTime != 0 {
                secondSlider.currentValue = Float(currentTime)
            }
        }
    }
    
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
        
        navigationItem.title = LANGLOC("Sensing & occasion change")
        confirmBtn.layer.cornerRadius = 8
        confirmBtn.backgroundColor = appMainThemeColor
        
        //秒
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
        let secondSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: secondTimeBgView.height), minValue: 5, maxValue: 60, step: 1)
        secondSlider.getValueTitle = { value in
            
            return String(format: "%ld%@", Int(value), LANGLOC("s"))
        }
        secondSlider.currentValue = secondSlider.minValue
        secondSlider.delegate = self
        self.secondSlider = secondSlider
        secondTimeBgView.addSubview(secondSlider)
        
        //分钟
        let mimuteSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: minuteTimeBgView.height), minValue: 10, maxValue: 120, step: 2)
        mimuteSlider.getValueTitle = { value in
            
            return String(format: "%ld%@", Int(value), LANGLOC("m"))
        }
        mimuteSlider.currentValue = mimuteSlider.minValue
        mimuteSlider.delegate = self
        self.mimuteSlider = mimuteSlider
        minuteTimeBgView.addSubview(mimuteSlider)
                
        //分类
        let str: String = Bundle.main.path(forResource: "OccasionPlist", ofType: "plist")!
        let occations: NSArray = try! NSArray.init(contentsOf: URL.init(fileURLWithPath: str), error: ())
        categoryList = KLMTool.jsonToModel(type: KLMType.self, array: occations as! [[String : Any]])!
        
        let str1: String = Bundle.main.path(forResource: "GroceriesPlist", ofType: "plist")!
        let groceries: NSArray = try! NSArray.init(contentsOf: URL.init(fileURLWithPath: str1), error: ())
        grocerySubTypes = KLMTool.jsonToModel(type: KLMType.self, array: groceries as! [[String : Any]])!
        allTypes = categoryList + grocerySubTypes
        
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 5) {
            self.hideEmptyView()
        }
        
        mimuteBtn.setTitle(LANGLOC("In minutes"), for: .normal)
        secondBtn.setTitle(LANGLOC("In seconds"), for: .normal)
        timeIntervalM.text = LANGLOC("Time interval(m)")
        timeINtervalS.text = LANGLOC("Time interval(s)")
        useOccasionLab.text = LANGLOC("Use occasion")
        confirmBtn.setTitle(LANGLOC("Confirm"), for: .normal)
        
    }
    
    private func setupData() {
        
        //读取数据
        let parame = parameModel(dp: .category)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
        
        DispatchQueue.main.asyncAfter(deadline: 1) {
            let parame = parameModel(dp: .colorTest)
            KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
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
    
    //秒
    @IBAction func secondClick(_ sender: UIButton) {
        
        currentTime = UInt16(secondSlider.currentValue)
    }
    
    //分
    @IBAction func minuteClick(_ sender: UIButton) {
        
        currentTime = UInt16(mimuteSlider.currentValue) * 60
        
    }
    
    @IBAction func confirmClick(_ sender: Any) {
        
        isTimeControl = true
        SVProgressHUD.show()
        let vv: Int = Int(currentTime)
        let parame = parameModel(dp: .colorTest, value: vv.decimalTo4Hexadecimal())
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
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
        currentTime = UInt16(vv)
    }
}

extension KLMCMOSViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if let value = message?.value as? Int, message?.dp == .category {
            
            let title: String = allTypes.first(where: {$0.num == value})!.title
            categoryLab.text = LANGLOC(title)
            if selectCategory != nil {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            }
        }
        
        if message?.dp ==  .colorTest, let value: Data = message?.value as? Data{
            hideEmptyView()
            if isTimeControl == false { //首次进来
                
                var time: UInt16 = 0
                (value as NSData).getBytes(&time, length:2)
                KLMLog("time = \(time)")
                currentTime = time
                
            } else {
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                DispatchQueue.main.asyncAfter(deadline: 0.5) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
