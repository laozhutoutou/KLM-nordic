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
    
    @IBOutlet weak var btnsView: UIView!
    
    var btnArray: [UIButton] = [UIButton]()
    
    var RSlider: KLMSlider!
    var GSlider: KLMSlider!
    var BSlider: KLMSlider!
    
    ///rgb 单路
    var enhance: RGBEnhance = RGBEnhance()
    var sure: sureBlock?
    var cancel: cancelBlock?
    var enhanceBlock: EnhanceBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        
        setupData()
    }
    
    private func setUI() {
        
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
        
        btnArray = btnsView.subviews as! [UIButton]
        
        //平均分配
        btnArray.snp.makeConstraints { make in
            make.height.equalTo(34)
            make.centerY.equalToSuperview()
        }
        btnArray.snp.distributeViewsAlong(axisType: .horizontal, fixedItemLength: 70, leadSpacing: 20, tailSpacing: 20)
    }
    
    private func setupData() {
        
        RSlider.currentValue = Float(enhance.RR)
        GSlider.currentValue = Float(enhance.GG)
        BSlider.currentValue = Float(enhance.BB)
        for btn in btnArray {
            btn.layer.cornerRadius = 3
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.gray.cgColor
            btn.clipsToBounds = true
            btn.setTitleColor(.white, for: .selected)
            btn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
            if btn.tag == enhance.classification {
                btn.isSelected = true
            }
        }
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
    
    @IBAction func classificationClick(_ sender: UIButton) {
        
        if sender.tag == enhance.classification {
            return
        }
        enhance.classification = sender.tag
        for btn in btnArray {
            btn.isSelected = false
        }
        sender.isSelected = true
        sendData()
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

class RGBEnhance {
    
    var RR: Int = 0
    var GG: Int = 0
    var BB: Int = 0
    var classification: Int = 0
}

