//
//  KLMWiFiModel.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/29.
//

import Foundation

struct KLMWiFiModel: Codable {
    var WiFiName: String
    var WiFiPass: String
}

class KLMWiFiManager {
    
    static func saveWiFiName(wifiModel: KLMWiFiModel?) {
        guard let wifiModel = wifiModel else {
            return
        }
        var WiFiLists: [KLMWiFiModel] = KLMWiFiManager.getWifiLists() ?? [KLMWiFiModel]()
        if let index = WiFiLists.firstIndex(where: {$0.WiFiName == wifiModel.WiFiName}) {
            WiFiLists[index] = wifiModel
        } else {
            WiFiLists.append(wifiModel)
        }
        KLMCache.setCache(model: WiFiLists, key: "wifilist")
    }

    static func getWifiLists() -> [KLMWiFiModel]? {
        return KLMCache.getCache([KLMWiFiModel].self, key: "wifilist")
    }
}
