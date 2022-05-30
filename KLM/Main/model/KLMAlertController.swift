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
    static func showAlertWithTitle(title: String?, message: String?) {
        
        let aler = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let sure = UIAlertAction.init(title: LANGLOC("sure"), style: .default, handler: nil)
        aler.addAction(sure)
        KLMKeyWindow?.rootViewController?.present(aler, animated: true, completion: nil)
    }
}
