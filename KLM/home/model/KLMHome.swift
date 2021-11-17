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
        var id: Int ///meshID 
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
        var meshName: String?
    }
}

struct KLMMeshUser: Codable {
    
    var data: [KLMMeshUserData]
    struct KLMMeshUserData: Codable {
        var id: Int ///用户ID
        var email: String
        var username: String?
    }
}

struct KLMInvitationCode: Codable {
    var data: KLMInvitationCodeData
    struct KLMInvitationCodeData: Codable {
        var result: String
    }
}

struct KLMVersion: Codable {
    var data: KLMVersionData
    struct KLMVersionData: Codable {
        var id: Int
        var fileUrl: String
        var fileVersion: String
        var updateMessage: String
    }
}
