//
//  EspDataUtils.swift
//  KLM
//
//  Created by 朱雨 on 2022/1/5.
//

import Foundation

class EspDataUtils {
    
    ///字节数组拼接
    static func mergeBytes(bytes: [UInt8], moreBytes: [UInt8] ...) -> [UInt8] {
        
        var result: [UInt8] = [UInt8]()
        result = bytes
        for data in moreBytes {
            result += data
        }
        return result
    }
    
    ///版本转化
    static func binVersionString2Int(version: String) -> Int {
        let splits = version.components(separatedBy: ".")
        var primary: Int = 0
        if let aa = splits[safeIndex: 0], let bb = Int(aa) {
            primary = bb & 0xff
        }
        var sub1: Int = 0
        if let aa = splits[safeIndex: 1], let bb = Int(aa) {
            sub1 = bb & 0xf
        }
        var sub2: Int = 0
        if let aa = splits[safeIndex: 2], let bb = Int(aa) {
            sub2 = bb & 0xf
        }
        return primary | (sub1 << 12) | (sub2 << 8)
    }
}
