//
//  KLMSearchDeviceEmptyView.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/20.
//

import UIKit

typealias ResearchBlock = () -> Void

class KLMSearchDeviceEmptyView: UIView {
    
    var researchBlock: ResearchBlock?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let image = UIImageView.init(image: UIImage.init(named: "img_Empty_Status"))
        self.addSubview(image)
        image.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(10)
        }
        
        let titleLab = UILabel()
        titleLab.text = LANGLOC("nodevicesfound")
        titleLab.font = UIFont.systemFont(ofSize: 14)
        titleLab.textColor = rgba(0, 0, 0, 0.5)
        self.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(image.snp.bottom).offset(16)
        }
        
        let research = UIButton()
        research.backgroundColor = appMainThemeColor
        research.setTitleColor(.white, for: .normal)
        research.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        research.setTitle(LANGLOC("research"), for: .normal)
        research.addTarget(self, action: #selector(researchClick), for: .touchUpInside)
        research.layer.cornerRadius = 20
        self.addSubview(research)
        research.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(140)
            make.height.equalTo(40)
            make.top.equalTo(titleLab.snp.bottom).offset(70)
        }
    }
    
    @objc func researchClick() {
        
        
        if let block = researchBlock {
            block()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
