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
    
    ///是否是手机号
    static func isPhone(phone: String) -> Bool {
        let phoneRegex: String = "^((13[0-9])|(15[^4,\\D])|(18[0,0-9])|(17[0,0-9]))\\d{8}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: phone)
    }
}
