//
//  KLMRippleAnimationView.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/10.
//

import UIKit

class KLMRippleAnimationView: UIView {
    
    //表示 Layer 的数量
    let pulsingCount = 2.0
    //表示动画时间
    let animationDuration = 3.0
    //设置扩散倍数。默认1.423倍
    let multiple = 4
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scaleAnimation() -> CABasicAnimation {
        
        let scaleAnimation = CABasicAnimation.init(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1
        scaleAnimation.toValue = multiple
        return scaleAnimation
    }
    
    func backgroundColorAnimation() -> CAKeyframeAnimation {
        
        let backgroundColorAnimation = CAKeyframeAnimation()
        backgroundColorAnimation.keyPath = "backgroundColor"
        backgroundColorAnimation.values = [rgba(255, 216, 87, 0.5).cgColor,
                                           rgba(255, 231, 152, 0.5).cgColor,
                                           rgba(255, 241, 197, 0.5).cgColor,
                                           rgba(255, 241, 197, 0).cgColor]
        backgroundColorAnimation.keyTimes = [0.3, 0.6, 0.9,1.0]
        return backgroundColorAnimation
    }
    
    func animationArray() -> [Any] {
        
        let scaleAni = scaleAnimation()
        let backgroundColorAni = backgroundColorAnimation()
        return [scaleAni, backgroundColorAni]
        
    }
    
    func animationGroupAnimations(array: [Any], index: Int) -> CAAnimationGroup {
        
        let animationGroup = CAAnimationGroup()
        animationGroup.beginTime = CACurrentMediaTime() + Double(index) * animationDuration  / pulsingCount
        animationGroup.duration = animationDuration
        animationGroup.repeatCount = HUGE;
        animationGroup.animations = array as? [CAAnimation]
        animationGroup.isRemovedOnCompletion = false
        animationGroup.timingFunction = CAMediaTimingFunction.init(name: .default)
        return animationGroup
        
    }
    
    func pulsingLayerr(rect: CGRect, animation: CAAnimationGroup) -> CALayer {
        
        let pulsingLayer = CALayer()
        pulsingLayer.frame = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height)
        pulsingLayer.cornerRadius = rect.size.height / 2
        pulsingLayer.add(animation, forKey: "plulsing")
        return pulsingLayer
    }
    
    override func draw(_ rect: CGRect) {
        
        let animationLayer = CALayer()
        
        for i in 0 ..< 3 {
            
            // 这里同时创建[缩放动画、背景色渐变、边框色渐变]三个简单动画
            let aniArray = animationArray()
            let animationGroup = animationGroupAnimations(array: aniArray, index: i)
            let pulsingLayer = pulsingLayerr(rect: rect, animation: animationGroup)
            animationLayer.addSublayer(pulsingLayer)
        }
        
        self.layer.addSublayer(animationLayer)
    }
    
}
