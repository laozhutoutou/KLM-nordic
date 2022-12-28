//
//  KLMAlertController.swift
//  KLM
//
//  Created by 朱雨 on 2022/5/27.
//

import Foundation

class KLMAlertController {
    
    /// 弹出提示框
    /// - Parameters:
    ///   - title: title
    ///   - message: message
    static func showAlertWithTitle(title: String?, message: String?, sure: (() -> ())? = nil) {
        
        let aler = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let sure = UIAlertAction.init(title: LANGLOC("Confirm"), style: .default, handler: { action in
            
            if let ss = sure {
                ss()
            }
        })
        aler.addAction(sure)
        KLMKeyWindow?.rootViewController?.present(aler, animated: true, completion: nil)
    }
}
