//
//  KLMTool.swift
//  KLM
//
//  Created by 朱雨 on 2022/4/22.
//

import Foundation

class KLMTool {
    
    //字符串转模型
    static func getModelFromString<T>(_ type: T.Type, from string: String?) -> T? where T : Codable  {
        
        guard let data = string?.data(using: .utf8) else { return nil }
        let model = try? JSONDecoder().decode(T.self, from: data)
        return model
    }
}
