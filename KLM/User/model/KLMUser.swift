//
//  KLMUser.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/12.
//

import Foundation

private let userKey = "userKey"

struct KLMUser: Codable {
    
    var data: KLMUserData
    struct KLMUserData: Codable {
        var token: String
        var userInfo: KLMUserInfo
        struct KLMUserInfo: Codable {
            var id: Int///用户ID
            var nickname: String
            var username: String?
        }
    }
    
    static func cacheUserInfo(user: KLMUserData.KLMUserInfo?)  {
        
        KLMCache.setCache(model: user, key: userKey)
    }
    
    static func getUserInfo() -> KLMUserData.KLMUserInfo? {
        
        return KLMCache.getCache(KLMUserData.KLMUserInfo.self, key: userKey)
    }
    
    static func removeUserInfo() {
        KLMCache.removeObject(key: userKey)
    }
}
