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
    var egMsg: String?
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
        var adminId: Int
    }
}

struct KLMMeshUser: Codable {
    
    var data: [KLMMeshUserData]
    struct KLMMeshUserData: Codable {
        var id: Int ///用户ID
        var email: String
        var username: String?
        var nickname: String?
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
        var isForceUpdate: Bool
        var englishMessage: String
    }
}

struct KLMGroupModel: Codable {
    var data: KLMGroupData
    struct KLMGroupData: Codable {
        var groupData: String
    }
}

class GroupData: Codable {
    var power: Int = 1
    var customColor: String = "#FFFFFF"
    var customColorTemp: Int = 0
    var customLight: Int = 100
    var energyPower: Int = 0
    var autoDim: Int = 1
    var brightness: Int = 100
    var colorSensing: Int = 1 //1 开 2-关
}

struct ProvisionerAddress: Codable {
    var data: KLMAddress
    struct KLMAddress: Codable {
        var address: Int
    }
}

struct KLMType: Codable {
    var title: String
    var num: Int
}


