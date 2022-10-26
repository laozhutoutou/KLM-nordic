//
//  KLMCache.swift
//  KLM
//
//  Created by 朱雨 on 2021/11/10.
//  存储类

import Foundation

class KLMCache {
    
    static func getCache<T>(_ type: T.Type, key name: String?) -> T? where T : Codable {
        
        guard let name = name else { return nil }
        if let fileURL = getCacheFile(name: name) {
            
            if FileManager.default.fileExists(atPath: fileURL.path) {
                
                let data = try! Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let model = try! decoder.decode(T.self, from: data)
                return model
            }
        }
        
        return nil
    }
    
    static func setCache<T: Codable>(model: T?, key name: String?) {
        guard let name = name else { return }
        guard let model = model else {
            removeObject(key: name)
            return
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try! encoder.encode(model)
        let fileURL = getCacheFile(name: name)
        try! data.write(to: fileURL!)
    }
    
    static func removeObject(key: String?) {
        
        guard let key = key else { return }
        let fileURL = getCacheFile(name: key)
        if let file = fileURL {
            try? FileManager.default.removeItem(at: file)
        }
    }
    
    private static func getCacheFile(name: String) -> URL? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return url?.appendingPathComponent(name)
    }
}
