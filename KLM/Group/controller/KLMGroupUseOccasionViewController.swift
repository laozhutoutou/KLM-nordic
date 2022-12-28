//
//  KLMGroupUseOccasionViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/23.
//

import UIKit

class KLMGroupUseOccasionViewController: UIViewController, Editable {
    
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
    
    ///分组数据
    var groupData: GroupData = GroupData()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        setupData()
        
        showEmptyView()
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
        
        mimuteBtn.setTitle(LANGLOC("In minutes"), for: .normal)
        secondBtn.setTitle(LANGLOC("In seconds"), for: .normal)
        timeIntervalM.text = LANGLOC("Time interval(m)")
        timeINtervalS.text = LANGLOC("Time interval(s)")
        useOccasionLab.text = LANGLOC("Use occasion")
        confirmBtn.setTitle(LANGLOC("Confirm"), for: .normal)
        
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
        
        currentTime = self.groupData.intervalTime
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
    
    //秒
    @IBAction func secondClick(_ sender: UIButton) {
        
        currentTime = UInt16(secondSlider.currentValue)
    }
    
    //分
    @IBAction func minuteClick(_ sender: UIButton) {
        
        currentTime = UInt16(mimuteSlider.currentValue) * 60
        
    }
    
    @IBAction func confirmClick(_ sender: Any) {
        
        let parame = parameModel(dp: .category, value: selectCategory!.num)
        KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {source in
            
            let vv: Int = Int(self.currentTime)
            let time = parameModel(dp: .colorTest, value: vv.decimalTo4Hexadecimal())
            KLMSmartGroup.sharedInstacnce.sendMessage(time, toGroup: KLMHomeManager.currentGroup) { source in
                
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                
                self.groupData.useOccasion = self.selectCategory!.num
                self.groupData.intervalTime = self.currentTime
                self.sendData()
                
            } failure: { error in
                KLMShowError(error)
            }

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

extension KLMGroupUseOccasionViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        
        var vv = Int(value)
        if slider == mimuteSlider {

            vv = vv * 60
        }
        currentTime = UInt16(vv)
    }
}
