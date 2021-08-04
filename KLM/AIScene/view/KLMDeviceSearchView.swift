//
//  KLMDeviceSearchView.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/10.
//

import UIKit

class KLMDeviceSearchView: UIView, Nibloadable {
    
    @IBOutlet weak var contentView: UIView!
    
    static var myframe: CGRect!
    
    static func deviceSearchView(frame: CGRect) -> KLMDeviceSearchView {
        
        let view = KLMDeviceSearchView.loadNib()
        view.backgroundColor = appBackGroupColor
        myframe = frame
        return view
    }
    
    override func draw(_ rect: CGRect) {
        self.frame = KLMDeviceSearchView.myframe
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let ripperView = KLMRippleAnimationView(frame: contentView.bounds)
        contentView.addSubview(ripperView)
    }
}
