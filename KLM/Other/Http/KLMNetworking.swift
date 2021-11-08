//
//  KLMNetworking.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/4.
//

import UIKit
import Alamofire
import SwiftUI

typealias KLMResponseSuccess = (_ response: AnyObject) -> Void
typealias KLMResponseFailure = (_ error: NSError) -> Void
typealias completionHandlerBlock = (_ responseObject: [String: AnyObject]?, _ error: NSError?) -> Void

enum HTTPMethod: String {
    case post
    case get
    case delete
    case put
}

class KLMNetworking: NSObject {
    
    private var networkingTool: AFHTTPSessionManager!
    
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
    
    private static var header: [String: String]? {
        guard let token = KLMGetUserDefault("token") as? String else {
            return nil
        }
        
        return ["Authorization": token]
    }
    ///请求头
    private static func sessionManagerWithHeader(head: [String: String]?) -> AFHTTPSessionManager{
        
        KLMNetworking.ShareInstance.networkingTool.requestSerializer = AFJSONRequestSerializer.init()
        KLMNetworking.ShareInstance.networkingTool.requestSerializer.timeoutInterval = 10
        if let hee = head {
            for (key, value) in hee {
                KLMNetworking.ShareInstance.networkingTool.requestSerializer.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return KLMNetworking.ShareInstance.networkingTool
    }
    ///请求方法分类
    private static func httpMethodSub(method: HTTPMethod? = .post, URLString: String,
                           params: [String: Any]?,
                           successBlock: @escaping (_ task: URLSessionDataTask, _ responseObject: Any?) -> Void,
                           failureBlock: @escaping (_ task: URLSessionDataTask?, _ error: Error) -> Void
    ) {
        
        switch method {
        case .post:
            self.sessionManagerWithHeader(head: header).post(URLString, parameters: params, progress: nil, success: successBlock, failure: failureBlock)
        case .get:
            self.sessionManagerWithHeader(head: header).get(URLString, parameters: params, progress: nil, success: successBlock, failure: failureBlock)
        case .put:
            self.sessionManagerWithHeader(head: header).put(URLString, parameters: params, success: successBlock, failure: failureBlock)
        case .delete:
            self.sessionManagerWithHeader(head: header).delete(URLString, parameters: params, success: successBlock, failure: failureBlock)
        default:
            break
        }
    }
    ///发送http请求
    static func httpMethod(method: HTTPMethod? = .post, URLString: String,
              params: [String: Any]?,
                     completion: @escaping completionHandlerBlock) {
        
        self.httpMethodSub(method: method, URLString: URLString, params: params) { task, responseObject in
            KLMLog("接口域名：\(URLString)\n请求返回数据: ")
            KLMLog(responseObject)
            
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
            
        } failureBlock: { task, error in
            SVProgressHUD.dismiss()
            KLMLog("接口域名：\(URLString)\n错误信息: ")
            KLMLog(error)
            let errors: NSError = error as NSError
            if errors.code == -1011 {///token过期，重新登录
                ///清空数据
                KLMSetUserDefault("token", nil)
                
                let appdelegate = UIApplication.shared.delegate as! AppDelegate
                appdelegate.enterLoginUI()
            }
            
            let resultDic = ["error": error.localizedDescription]
            let error = NSError.init(domain: "", code: -1, userInfo: resultDic as [String : Any])
            completion(nil, error)
        }
    }
}

class KLMService: NSObject {
    
    static func getCode(email: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["email": email]
        KLMNetworking.httpMethod(method: .get, URLString: KLMUrl("open/email/code"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func login(username: String, password: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["username": username,
                      "password": password]
        KLMNetworking.httpMethod(URLString: KLMUrl("api/auth/login"), params: parame) { responseObject, error in
            
            if error == nil {
                //登录成功，存储token
                if let data = responseObject?["data"] as? [String: AnyObject], let token = data["token"] as? String{
                    KLMLog("登录成功：token = \(token)")
                    KLMSetUserDefault("token", token)
                }
                
                success(responseObject as AnyObject)
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
        KLMNetworking.httpMethod(URLString: KLMUrl("api/auth/register"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func logout(success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        KLMNetworking.httpMethod(URLString: KLMUrl("api/auth/logout"), params: nil) { responseObject, error in
            
            if error == nil {
                
                KLMSetUserDefault("token", nil)
                
                success(responseObject as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func addMesh(meshName: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let config = KLMMesh.createMesh()
        let parame = ["meshName": meshName,
                      "meshConfiguration": config
                    ]
        KLMNetworking.httpMethod(URLString: KLMUrl("api/mesh"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func addSearch(searchContent: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["searchContent": searchContent
                    ]
        KLMNetworking.httpMethod(URLString: KLMUrl("api/search"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func getHistoryData(page: String, limit: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["page": page,
                      "limit": limit
                    ]
        KLMNetworking.httpMethod(method: .get, URLString: KLMUrl("api/search/page"), params: parame) { responseObject, error in
            
            if error == nil {
                
                var datas: [String] = [String]()
                if let data = responseObject?["data"] as? [AnyObject] {
                    
                    for item in data {
                        
                        if let dic: [String: AnyObject] = item as? [String : AnyObject], let searchContent: String = dic["searchContent"] as? String {
                            datas.append(searchContent)
                        }
                    }
                }
                
                success(datas as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
}
