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
///列表数据
struct KLMHome: Codable {
    
    var data: KLMHomeData
    struct KLMHomeData: Codable {
        var admin: [KLMHomeModel]
        var participant: [KLMHomeModel]
    }
    struct KLMHomeModel: Codable {
        var meshName: String
        var id: Int ///meshID 
        var adminId: Int///管理员ID
        var meshConfiguration: String
    }
}

struct KLMHistory: Codable {
    
    var data: [KLMHistoryData]
    struct KLMHistoryData: Codable {
        var searchContent: String
    }
}
///mesh具体数据
struct KLMMeshInfo: Codable {
    
    var data: KLMMeshInfoData
    struct KLMMeshInfoData: Codable {
        var id: Int ///meshID
        var meshConfiguration: String
        var meshName: String
        var adminId: Int///管理员ID
    }
}

struct KLMMeshUser: Codable {
    
    var data: [KLMMeshUserData]
    struct KLMMeshUserData: Codable {
        var id: Int ///用户ID
        var email: String?
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

class GroupData: BaseModel, Codable {
    var power: Int = 1 //开关 1-开 2-关
    var customColor: String = "#FFFFFF" //自定义颜色
    var customColorTemp: Int = 0 //自定义色温
    var customLight: Int = 100 //自定义亮度
    var energyPower: Int = 0 //节能开关
    var autoDim: Int = 1 //节能时间 单位分钟
    var brightness: Int = 100 //节能亮度
    var colorSensing: Int = 1 //自动模式1 开 2-关
    var useOccasion: Int = 2 //使用场合
    var intervalTime: UInt16 = 20 * 60 //全自动 - 间隔时间
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


