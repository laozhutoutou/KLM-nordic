//
//  KLMHome.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/5.
//

import Foundation

struct KLMBaseModel: Codable {
    
    var code: Int
    var msg: String
}

struct KLMHome: Codable {
    
    var data: KLMHomeData
    struct KLMHomeData: Codable {
        var admin: [KLMHomeModel]
        var participant: [KLMHomeModel]
    }
    struct KLMHomeModel: Codable {
        var meshName: String
        var id: Int
        var adminId: Int?///管理员ID
        var meshConfiguration: String
    }
}

struct KLMHistory: Codable {
    
    var data: [KLMHistoryData]
    struct KLMHistoryData: Codable {
        var searchContent: String
    }
}

struct KLMMeshInfo: Codable {
    
    var data: KLMMeshInfoData
    struct KLMMeshInfoData: Codable {
        var meshConfiguration: String
    }
}

struct KLMMeshUser: Codable {
    
    var data: [KLMMeshUserData]
    struct KLMMeshUserData: Codable {
        var id: Int
        var email: String
        var username: String?
    }
}
