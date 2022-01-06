//
//  EspDataUtils.swift
//  KLM
//
//  Created by 朱雨 on 2022/1/5.
//

import Foundation

enum Constant: String {
    case KEY_DST_ADDRESS = "dstAddress"
    case KEY_COMPANY_ID = "companyId"
    case KEY_VERSION_CODE = "versionCode"
    case KEY_BIN_ID = "binId"
    case KEY_CLEAR_FLASK = "clearFlash"
    case KEY_URL = "url"
    case KEY_URL_SSID = "urlSsid"
    case KEY_URL_PASSWORD = "urlPassword"
}

class EspDataUtils {
    
    static func mergeBytes(bytes: [UInt8], moreBytes: [UInt8] ...) -> [UInt8] {
        
        var result: [UInt8] = [UInt8]()
        result = bytes
        for data in moreBytes {
            result += data
        }
        return result
    }
}
