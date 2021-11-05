//
//  KLMNetworking.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/4.
//

import UIKit
import Alamofire

typealias KLMResponseSuccess = (_ response: [String: AnyObject]) -> Void
typealias KLMResponseFailure = (_ error: NSError) -> Void

typealias completionHandlerBlock = (_ responseObject: [String: AnyObject]?, _ error: NSError?) -> Void

class KLMNetworking: NSObject {
    
    var networkingTool: AFHTTPSessionManager!
    
    static let ShareInstance = KLMNetworking()
    private override init() {
        super.init()
        networkingTool = AFHTTPSessionManager.init()
        let jsonType = "application/json"
        let textType = "text/html"
        let plainType = "text/plain"
        let set = NSSet.init(array: [jsonType,textType,plainType])
        networkingTool.responseSerializer.acceptableContentTypes = set as? Set<String>
    }
    
    static var header: [String: String]? {
        guard let token = KLMGetUserDefault("token") as? String else {
            return nil
        }
        
        return ["Authorization": token]
    }
    
    static func sessionManagerWithHeader(head: [String: String]?) -> AFHTTPSessionManager{
        
        KLMNetworking.ShareInstance.networkingTool.requestSerializer = AFJSONRequestSerializer.init()
        KLMNetworking.ShareInstance.networkingTool.requestSerializer.timeoutInterval = 10
        if let hee = head {
            for (key, value) in hee {
                KLMNetworking.ShareInstance.networkingTool.requestSerializer.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return KLMNetworking.ShareInstance.networkingTool
    }
    
    static func POST(URLString: String,
              params: [String: Any]?,
              completion: @escaping completionHandlerBlock) {
        
        KLMLog("接口域名：\(URLString)\n请求参数：\(String(describing: params))")
        self.sessionManagerWithHeader(head: header).post(URLString, parameters: params, progress: nil) { task, responseObject in
            KLMLog("接口域名：\(URLString)\n请求返回数据: \(String(describing: responseObject))")
            
            guard let dic: [String: AnyObject] = responseObject as? [String : AnyObject] else {
                SVProgressHUD.dismiss()
                let resultDic = ["error": "Unknow error"]
                let error = NSError.init(domain: "", code: -1, userInfo: resultDic)
                completion(nil, error)
                return
            }
            
            guard dic["code"] as? Int == 200 else {
                SVProgressHUD.dismiss()
                let msg = dic["msg"]
                let resultDic = ["error": msg]
                let error = NSError.init(domain: "", code: -1, userInfo: resultDic as [String : Any])
                completion(nil, error)
                return
            }
            
            
            completion(dic, nil)
            
        } failure: { task, error in
            SVProgressHUD.dismiss()
            
            let resultDic = ["error": error.localizedDescription]
            let error = NSError.init(domain: "", code: -1, userInfo: resultDic as [String : Any])
            completion(nil, error)
        }

    }
    
    static func GET(URLString: String,
              params: [String: Any]?,
              completion: @escaping completionHandlerBlock) {
        
        KLMLog("接口域名：\(URLString)\n请求参数：\(String(describing: params))")
        self.sessionManagerWithHeader(head: header).get(URLString, parameters: params, progress: nil) { task, responseObject in
            KLMLog("接口域名：\(URLString)\n请求返回数据: \(String(describing: responseObject))")
            
            guard let dic: [String: AnyObject] = responseObject as? [String : AnyObject] else {
                SVProgressHUD.dismiss()
                let resultDic = ["error": "Unknow error"]
                let error = NSError.init(domain: "", code: -1, userInfo: resultDic)
                completion(nil, error)
                return
            }
            
            guard dic["code"] as? Int == 200 else {
                SVProgressHUD.dismiss()
                let msg = dic["msg"]
                let resultDic = ["error": msg]
                let error = NSError.init(domain: "", code: -1, userInfo: resultDic as [String : Any])
                completion(nil, error)
                return
            }
            
            
            completion(dic, nil)
            
        } failure: { task, error in
            SVProgressHUD.dismiss()
            
            let resultDic = ["error": error.localizedDescription]
            let error = NSError.init(domain: "", code: -1, userInfo: resultDic as [String : Any])
            completion(nil, error)
        }
    }
}

class KLMService: NSObject {
    
    static func getCode(email: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["email": email]
        KLMNetworking.GET(URLString: KLMUrl("open/email/code"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject!)
            } else {
                failure(error!)
            }
        }
    }
    
    static func login(username: String, password: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["username": username,
                      "password": password]
        KLMNetworking.POST(URLString: KLMUrl("api/auth/login"), params: parame) { responseObject, error in
            
            if error == nil {
                //登录成功，存储token
                if let data = responseObject?["data"] as? [String: AnyObject], let token = data["token"] as? String{
                    KLMLog("登录成功：token = \(token)")
                    KLMSetUserDefault("token", token)
                }
                
                success(responseObject!)
            } else {
                failure(error!)
            }
        }
    }
    
    static func register(email: String, password: String, code: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["email": email,
                      "username": "zhuyu",
                      "nickname": "zhuyu",
                      "password": password,
                      "code": code]
        KLMNetworking.POST(URLString: KLMUrl("api/auth/register"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject!)
            } else {
                failure(error!)
            }
        }
    }
    
    static func logout(success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        KLMNetworking.POST(URLString: KLMUrl("api/auth/logout"), params: nil) { responseObject, error in
            
            if error == nil {
                
                KLMSetUserDefault("token", nil)
                
                success(responseObject!)
            } else {
                failure(error!)
            }
        }
    }
    
    static func addSearch(searchContent: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["searchContent": searchContent
                    ]
        KLMNetworking.POST(URLString: KLMUrl("api/search"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject!)
            } else {
                failure(error!)
            }
        }
    }
}
