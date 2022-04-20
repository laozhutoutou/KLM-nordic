//
//  KLMVerifyManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/4/20.
//

import Foundation

class KLMVerifyManager {
    
    ///是否是邮箱
    static func isEmail(email: String) -> Bool{
        let emailStr = "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailStr)
        return emailPredicate.evaluate(with: email)
    }
    
}
