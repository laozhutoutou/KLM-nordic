//
//  KLMPhotoEditMoreViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/5/12.
//

import UIKit

typealias EnhanceBlock = (_ enhan: RGBEnhance) -> Void

class KLMPhotoEditMoreViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var RBgView: UIView!
    @IBOutlet weak var GBgView: UIView!
    @IBOutlet weak var BBgView: UIView!
    
    var RSlider: KLMSlider!
    var GSlider: KLMSlider!
    var BSlider: KLMSlider!
    
    ///rgb 单路
    var enhance: RGBEnhance = RGBEnhance()
    
    var enhanceBlock: EnhanceBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        
        setupData()
    }
    
    private func setUI() {
        
        contentView.layer.cornerRadius = 8
        
        //R滑条
        let viewLeft: CGFloat = 20
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
    }
    
    private func setupData() {
        
        RSlider.currentValue = Float(enhance.RR)
        GSlider.currentValue = Float(enhance.GG)
        BSlider.currentValue = Float(enhance.BB)
    }
    
    
    @IBAction func resetClick(_ sender: Any) {
        
        enhance.RR = 0
        enhance.BB = 0
        enhance.GG = 0
        
        sendData()
//        setupData()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func bgClick(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    private func sendData() {
        
        if let enhan = self.enhanceBlock {
            enhan(enhance)
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

class RGBEnhance {
    
    var RR: Int = 0
    var GG: Int = 0
    var BB: Int = 0
}

