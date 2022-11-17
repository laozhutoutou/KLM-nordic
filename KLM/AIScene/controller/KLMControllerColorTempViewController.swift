//
//  KLMControllerColorTempViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/16.
//

import UIKit

private enum ColortempType {
    case ColortempTypeNormal
    case ColortempTypeWW
    case ColortempTypeCW
}

class KLMControllerColorTempViewController: UIViewController {

    @IBOutlet weak var plateView: UIView!
    @IBOutlet weak var colortempImageView: UIImageView!
    
    @IBOutlet weak var normalBtn: UIButton!
    @IBOutlet weak var WWBtn: UIButton!
    @IBOutlet weak var CWBtn: UIButton!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var lightBgView: UIView!
    @IBOutlet weak var WWLab: UILabel!
    @IBOutlet weak var CWLab: UILabel!
    
    private var lightValue: Int = 100
    private var lightSlider: KLMSlider!
    
    lazy var tapView: UIImageView = {
        let tapView = UIImageView()
        tapView.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        tapView.layer.cornerRadius = tapView.height / 2
        tapView.layer.borderColor = UIColor.black.cgColor
        tapView.layer.borderWidth = 1
        tapView.isHidden = true
        return tapView
    }()
    
    private var colorTempType: ColortempType = .ColortempTypeNormal {
        didSet {
            normalBtn.isSelected = false
            WWBtn.isSelected = false
            CWBtn.isSelected = false
            
            switch colorTempType {
            case .ColortempTypeNormal:
                normalBtn.isSelected = true
                colortempImageView.image = UIImage.init(named: "img_ColorTemp_Normal")
            case .ColortempTypeWW:
                WWBtn.isSelected = true
                colortempImageView.image = UIImage.init(named: "img_ColorTemp_WW")
            case .ColortempTypeCW:
                CWBtn.isSelected = true
                colortempImageView.image = UIImage.init(named: "img_ColorTemp_CW")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.layer.cornerRadius = 16
        
        navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(dimiss)) as? [UIBarButtonItem]
        
        setupUI()
    }
    
    func setupUI() {
        
        view.backgroundColor = appBackGroupColor
        plateView.backgroundColor =  appBackGroupColor
                        
        let viewLeft: CGFloat = 20 + 16
        let sliderWidth = KLMScreenW - viewLeft * 2
        
        //亮度滑条
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 1)
        lightSlider.getValueTitle = { value in

            return String(format: "%ld%%", Int(value))
        }
        lightSlider.delegate = self
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
        
        //点选
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(tap:)))
        plateView.addGestureRecognizer(tapRecognizer)
        
        //拖动
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
        plateView.addGestureRecognizer(panRecognizer)
        
        colorTempType = .ColortempTypeNormal
    }
    
    @objc func handleTap(tap: UITapGestureRecognizer) {
        
        let tapPoint = tap.location(in: plateView)
        if tap.state == .ended {
            tapView.isHidden = false
            plateView.addSubview(tapView)
            let point = getPoint(point: tapPoint)
            tapView.center = point
            let (WW, CW) = getWWAndCW(point: point)
            WWLab.text = "\(WW)"
            CWLab.text = "\(CW)"
        }
    }
    
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        
        if pan.state == .began {
            
            tapView.isHidden = false
            plateView.addSubview(tapView)
            
        }else if pan.state == .changed {
            
            let tapPoint = pan.location(in: plateView)
            let point = getPoint(point: tapPoint)
            tapView.center = point
            let (WW, CW) = getWWAndCW(point: point)
            WWLab.text = "\(WW)"
            CWLab.text = "\(CW)"
            
        }else if pan.state == .ended {
            
        }
    }
    
    @objc func dimiss() {
        
        dismiss(animated: true, completion: nil)
    }

    @IBAction func normal(_ sender: UIButton) {
        
        colorTempType = .ColortempTypeNormal
    }
    
    @IBAction func WW(_ sender: Any) {
        
        colorTempType = .ColortempTypeWW
    }
    
    @IBAction func CW(_ sender: Any) {
        
        colorTempType = .ColortempTypeCW
    }
    
    private func getCenterCircleR() -> CGFloat {
        return plateView.width * 3 / 8
    }
    
    private func getCircleG() -> CGFloat {
        return plateView.width / 2
    }
    
    private func getPoint(point: CGPoint) -> CGPoint {

        let centerR = getCenterCircleR()
        let circleR = getCircleG()
        let x: CGFloat = circleR - point.x
        let y: CGFloat = circleR - point.y
        let pointR: CGFloat = CGFloat(sqrtf(powf(Float(x), 2) + powf(Float(y), 2)))
        let scale = pointR / centerR
        let xx = circleR - x / scale
        let yy = circleR - y / scale
        return CGPoint(x: xx, y: yy)
    }
    
    private func getWWAndCW(point: CGPoint) -> (WW: Int, CW: Int){
        
        ///分为255格
        let D = plateView.width / 8 * 6
        let x = point.x - plateView.width / 8
        let V: Int = Int(x * 255 / D)
        switch colorTempType {
        case .ColortempTypeNormal:
            return (255 - V, V)
        case .ColortempTypeWW:
            return (V, 0)
        case .ColortempTypeCW:
            return (0, V)
        }
    }
}

extension KLMControllerColorTempViewController: KLMSliderDelegate {

    func KLMSliderWith(slider: KLMSlider, value: Float) {
            
        if slider == lightSlider { //亮度
            let vv = Int(value)
//            let parame = parameModel(dp: .light, value: vv)
//            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
}
