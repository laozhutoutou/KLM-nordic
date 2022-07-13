//
//  protocol.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/11.
//

import Foundation

protocol Nibloadable {
    
    
}

//当编写protocol和针对protocol进行扩展时，Self（大写S）和self（小写S）之间存在差异。当与大写S一起使用时，Self指的是符合协议的类型，例如String或Int。当与小写S一起使用时，self指的是该类型内的值，例如“hello”或556。
//extension BinaryInteger {
//    func squared() -> Self {
//        return self * self
//    }
//注意:“Self”仅在协议中可用，或者作为类中方法的结果
extension Nibloadable where Self : UIView {
    
    static func loadNib(_ nibName: String? = nil) -> Self {
        
        return Bundle.main.loadNibNamed(nibName ?? "\(self)", owner: nil, options: nil)?.first as! Self
    }
}
