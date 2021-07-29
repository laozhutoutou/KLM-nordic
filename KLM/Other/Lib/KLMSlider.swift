//
//  KLMSlider.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/2.
//

import UIKit

protocol KLMSliderDelegate: AnyObject {

    func KLMSliderWith(slider: KLMSlider,value: Float)
}

typealias GetValueTitle = (_ value: Float) -> String

class KLMSlider: UIView {
    
    var minValue: Float = 0
    var maxValue: Float = 0
    /// 加减步值
    var step: Float = 0
    lazy var slider: KLMSliderW = {
        let slider = KLMSliderW.init()
        slider.minimumTrackTintColor = .black
        slider.maximumTrackTintColor = .lightGray
        slider.addTarget(self, action: #selector(valueChange(slider:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(touchUp(slider:)), for: .touchUpInside)
        slider.addTarget(self, action: #selector(touchUp(slider:)), for: .touchUpOutside)
        return slider
    }()
    
    lazy var minBtn: UIButton = {
        let minBtn = UIButton.init(type: .custom)
        minBtn.setImage(UIImage.init(named: "icon_decrease"), for: .normal)
        minBtn.addTarget(self, action: #selector(minClick), for: .touchUpInside)
        return minBtn
    }()
    
    lazy var maxBtn: UIButton = {
        let maxBtn = UIButton.init(type: .custom)
        maxBtn.setImage(UIImage.init(named: "icon_add"), for: .normal)
        maxBtn.addTarget(self, action: #selector(maxClick), for: .touchUpInside)
        return maxBtn
    }()
    //指示器
    var indicateView: KLMIndicateView!
    
    //设置标题
    var getValueTitle: GetValueTitle?
    weak var delegate: KLMSliderDelegate?
    //指示器的宽度
    var indicateViewWidth: CGFloat = 35 {
        
        didSet {
            
            indicateView.snp.updateConstraints { make in
                make.width.equalTo(indicateViewWidth)
            }
        }
    }
    
    
    var currentValue: Float = 0 {
        didSet {
            if currentValue < minValue {
                currentValue = minValue
                
            }
            
            if currentValue > maxValue {
                currentValue = maxValue
            }
            
            //滑块
            self.slider.value = currentValue
            
            //标签
            let labX = Float(self.slider.width) * (currentValue - self.minValue)  / (self.maxValue - self.minValue)
            indicateView.snp.updateConstraints { make in
                make.centerX.equalTo(slider.snp.left).offset(labX)
            }
            
            if let block = self.getValueTitle {
                
                indicateView.title = block(currentValue)
            }
        }
    }
    
    init(frame: CGRect, minValue: Float, maxValue: Float, step: Float) {
        super.init(frame: frame)
        
        self.minValue = minValue
        self.maxValue = maxValue
        self.step = step
        self.slider.minimumValue = minValue
        self.slider.maximumValue = maxValue
//        self.backgroundColor = UIColor.orange
        self.setupUI()
    }
    
    func setupUI() {
        
        self.addSubview(minBtn)
        self.addSubview(maxBtn)
        self.addSubview(slider)
        
        minBtn.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview().offset(-8)
        }
        
        maxBtn.snp.makeConstraints { make in
            make.centerY.equalTo(minBtn)
            make.right.equalToSuperview()
        }
    
        slider.snp.makeConstraints { make in
            make.centerY.equalTo(minBtn)
            make.left.equalTo(minBtn.snp.right).offset(15)
            make.right.equalTo(maxBtn.snp.left).offset(-15)
        }
        self.setNeedsLayout()
        indicateView = KLMIndicateView()
        self.addSubview(indicateView)
//        indicateView.isHidden = true
        
        indicateView.snp.makeConstraints { make in
            make.width.equalTo(indicateViewWidth)
            make.height.equalTo(28)
            make.bottom.equalTo(slider.snp.top).offset(-5)
            make.centerX.equalTo(slider.snp.left)
        }
    }
    
    @objc func minClick() {
        
        indicateView.isHidden = false
        self.currentValue -= self.step
        setData()
    }
    
    @objc func maxClick() {
        indicateView.isHidden = false
        self.currentValue += self.step
        setData()
    }
    
    @objc func valueChange(slider: KLMSliderW) {
        
        indicateView.isHidden = false
        self.currentValue = slider.value
    }
    
    @objc func touchUp(slider: KLMSliderW) {
        KLMLog("value = \(slider.value)")
        self.currentValue = slider.value
        setData()
    }
    
    func setData() {
        
        self.delegate?.KLMSliderWith(slider: self, value: self.currentValue)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class KLMSliderW: UISlider {
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let sliderH: CGFloat = 7
        let sliderY: CGFloat = self.height / 2 - sliderH / 2
        
        return CGRect.init(x: 0, y: sliderY, width: self.width, height: sliderH)
    }
    
}

class KLMIndicateView: UIView {
    
    lazy var lab: UILabel = {
        let lab = UILabel()
        lab.backgroundColor = rgb(122, 122, 122)
        lab.textColor = .white
        lab.font = UIFont.systemFont(ofSize: 12)
        lab.textAlignment = .center
        lab.layer.cornerRadius = 2
        lab.clipsToBounds = true
        return lab
    }()
    
    var title: String = "" {
        
        didSet {
            self.lab.text = title
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        self.addSubview(self.lab)
        
        self.lab.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(22)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        drawBackground(frame: self.bounds)
    }
    
    func drawBackground(frame: CGRect) {
        
        let left: CGFloat = frame.midX  - 6
        let right: CGFloat = frame.midX + 6
        let y0: CGFloat = 22
        let y1: CGFloat = frame.size.height
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: left, y: y0))
        path.addLine(to: CGPoint(x: frame.midX, y: y1))
        path.addLine(to: CGPoint(x: right, y: y0))
        path.close()
        rgb(122, 122, 122).set()
        rgb(122, 122, 122).setStroke()
        path.stroke()
        path.fill()
        
    }

}
