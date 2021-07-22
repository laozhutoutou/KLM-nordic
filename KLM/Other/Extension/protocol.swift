//
//  protocol.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/11.
//

import Foundation

protocol Nibloadable {
    
    
}

extension Nibloadable where Self : UIView {
    
    static func loadNib(_ nibName: String? = nil) -> Self {
        
        return Bundle.main.loadNibNamed(nibName ?? "\(self)", owner: nil, options: nil)?.first as! Self
    }
}
