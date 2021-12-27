//
//  KLMNetworking.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/4.
//

import UIKit
import Alamofire
import SwiftUI
import nRFMeshProvision

typealias KLMResponseSuccess = (_ response: AnyObject) -> Void
typealias KLMResponseFailure = (_ error: NSError) -> Void
typealias completionHandlerBlock = (_ responseObject: Data?, _ error: NSError?) -> Void

enum HTTPMethod: String {
    case post
    case get
    case delete
    case put
    case downLoad
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
    ///JSON类型数据
    static func jsonManagerWithHeader(head: [String: String]?) -> AFHTTPSessionManager{
        
        KLMNetworking.ShareInstance.networkingTool.responseSerializer = AFJSONResponseSerializer.init()
        KLMNetworking.ShareInstance.networkingTool.requestSerializer = AFJSONRequestSerializer.init()
        KLMNetworking.ShareInstance.networkingTool.requestSerializer.timeoutInterval = 10
        if let hee = head {
            for (key, value) in hee {
                KLMNetworking.ShareInstance.networkingTool.requestSerializer.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return KLMNetworking.ShareInstance.networkingTool
    }
    ///data类型数据
    private static func httpManagerWithHeader(head: [String: String]?) -> AFHTTPSessionManager{
        
        KLMNetworking.ShareInstance.networkingTool.responseSerializer = AFHTTPResponseSerializer.init()
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
            self.jsonManagerWithHeader(head: header).post(URLString, parameters: params, progress: nil, success: successBlock, failure: failureBlock)
        case .get:
            self.jsonManagerWithHeader(head: header).get(URLString, parameters: params, progress: nil, success: successBlock, failure: failureBlock)
        case .put:
            self.jsonManagerWithHeader(head: header).put(URLString, parameters: params, success: successBlock, failure: failureBlock)
        case .delete:
            self.jsonManagerWithHeader(head: header).delete(URLString, parameters: params, success: successBlock, failure: failureBlock)
        case .downLoad:
            self.httpManagerWithHeader(head: header).get(URLString, parameters: params, progress: nil, success: successBlock, failure: failureBlock)
        default:
            break
        }
    }
    ///发送http请求
    static func httpMethod(method: HTTPMethod? = .post, URLString: String,
              params: [String: Any]?,
                     completion: @escaping completionHandlerBlock) {
        KLMLog("接口域名：\(URLString)\n请求参数：\(String(describing: params))")
        self.httpMethodSub(method: method, URLString: URLString, params: params) { task, responseObject in
            KLMLog("接口域名：\(URLString)\n请求返回数据: ")
            KLMLog(responseObject)
            
            if method == .downLoad {
                
                let data: NSData = responseObject as! NSData
                completion(data as Data, nil)
                return
            }
            
            do {
                ///json转data
                let data = try JSONSerialization.data(withJSONObject: responseObject as Any, options: [])
                ///data转model
                let model = try JSONDecoder().decode(KLMBaseModel.self, from: data)
                if model.code == 200 {
                    
                    completion(data, nil)
                    
                } else {
                    SVProgressHUD.dismiss()
                    let msg = model.msg
                    var egMsg = model.egMsg
                    if egMsg == nil {
                        egMsg = msg
                    }
                    let resultDic = ["error": msg, "egMsg": egMsg]
                    let error = NSError.init(domain: "", code: model.code, userInfo: resultDic as [String : Any])
                    completion(nil, error)
                }
            } catch {
                SVProgressHUD.dismiss()
                let resultDic = ["error": error.localizedDescription, "egMsg": error.localizedDescription]
                let error = NSError.init(domain: "", code: -1, userInfo: resultDic)
                completion(nil, error)
            }
            
        } failureBlock: { task, error in
            SVProgressHUD.dismiss()
            KLMLog("接口域名：\(URLString)\n错误信息: ")
            KLMLog(error)
            let errors: NSError = error as NSError
            if errors.code == -1011 {
                
                let errorData = errors.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as! Data
                let errorDic: [String: AnyObject] = try! JSONSerialization.jsonObject(with: errorData, options: .mutableContainers) as! [String: AnyObject]
                let StateCode = errorDic["code"] as! Int
                if StateCode == 400 { ///token过期，重新登录
                    ///清空数据
                    KLMMesh.logout()
                    KLMLog("token 失效")
                    let appdelegate = UIApplication.shared.delegate as! AppDelegate
                    appdelegate.enterLoginUI()
                }
            
            }
            
            let resultDic = ["error": error.localizedDescription, "egMsg": error.localizedDescription]
            let error = NSError.init(domain: "", code: errors.code, userInfo: resultDic as [String : Any])
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
                
                let model = try? JSONDecoder().decode(KLMUser.self, from: responseObject!)
                
                //登录成功，存储token
                KLMLog("登录成功：token = \(String(describing: model?.data.token))")
                KLMSetUserDefault("token", model?.data.token)
                
                ///存储个人账号密码
                KLMSetUserDefault("username", username)
                KLMSetUserDefault("password", password)
                
                ///存储个人信息
                KLMUser.cacheUserInfo(user: model?.data.userInfo)
                
                success(responseObject as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func register(email: String, password: String, code: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["email": email,
                      "password": password,
                      "code": code,
                      "nickname": LANGLOC("unknowUser")]
        KLMNetworking.httpMethod(URLString: KLMUrl("api/auth/register"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func resetPassword(email: String, password: String, code: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["email": email,
                      "password": password,
                      "code": code]
        KLMNetworking.httpMethod(URLString: KLMUrl("api/auth/reset/password"), params: parame) { responseObject, error in
            
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
                ///清空数据
                KLMMesh.logout()
                
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
                 
                let model = try? JSONDecoder().decode(KLMHistory.self, from: responseObject!)
                
                success(model as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func getMeshList(success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        KLMNetworking.httpMethod(method: .get, URLString: KLMUrl("api/mesh/adminId"), params: nil) { responseObject, error in
            
            if error == nil {
                
                let model = try? JSONDecoder().decode(KLMHome.self, from: responseObject!)
                var homes: [KLMHome.KLMHomeModel]  = []
                if let model = model {
                    homes = model.data.admin + model.data.participant
                }
                success(homes as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func clearAllHistory(success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        KLMNetworking.httpMethod(method: .delete, URLString: KLMUrl("api/search/clearAll"), params: nil) { responseObject, error in
            
            if error == nil {
                
                success(responseObject as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func editMesh(id: Int, meshName: String?, meshConfiguration: String?, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        var parame = ["id": id] as [String : Any]
        if meshName != nil {
            parame["meshName"] = meshName
        }
        if meshConfiguration != nil {
            parame["meshConfiguration"] = meshConfiguration
        }
        
        KLMNetworking.httpMethod(method: .put, URLString: KLMUrl("api/mesh/\(id)"), params: parame) { responseObject, error in
            
            if error == nil {
                success(responseObject as AnyObject)
            } else {
                failure(error!)
            }
        }
    }
    
    static func deleteMesh(id: Int, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        KLMNetworking.httpMethod(method: .delete, URLString: KLMUrl("api/mesh/\(id)"), params: nil) { responseObject, error in
            
            if error == nil {
                
                success(responseObject as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func getMeshInfo(id: Int, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        KLMNetworking.httpMethod(method: .get, URLString: KLMUrl("api/mesh/\(id)"), params: nil) { responseObject, error in
            
            if error == nil {
                
                let model = try? JSONDecoder().decode(KLMMeshInfo.self, from: responseObject!)
                let meshInfo = model?.data
                success(meshInfo as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func getMeshUsers(meshId: Int, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["meshId": meshId]
        KLMNetworking.httpMethod(method: .get, URLString: KLMUrl("api/mesh/meshId"), params: parame) { responseObject, error in
            
            if error == nil {
                
                let model = try? JSONDecoder().decode(KLMMeshUser.self, from: responseObject!)
                success(model as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func feedBack(contacts: String, content: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["email": contacts,
                      "content": content]
        KLMNetworking.httpMethod(URLString: KLMUrl("api/feedBack"), params: parame) { responseObject, error in
            
            if error == nil {
                
                success(responseObject as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func getInvitationCode(meshId: Int, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["meshId": meshId]
        KLMNetworking.httpMethod(method: .get, URLString: KLMUrl("api/mesh/invitationCode"), params: parame) { responseObject, error in
            
            if error == nil {
                
                let model = try? JSONDecoder().decode(KLMInvitationCode.self, from: responseObject!)
                let code = model?.data.result
                success(code as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func joinToHome(invitationCode: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["invitationCode": invitationCode]
        KLMNetworking.httpMethod(method: .get, URLString: KLMUrl("api/mesh/json"), params: parame) { responseObject, error in
            
            if error == nil {
                
                success(responseObject as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func deleteUser(meshId: Int, userId: Int, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        let parame = ["meshId": meshId,
                      "userId": userId]
        KLMNetworking.httpMethod(method: .delete, URLString: KLMUrl("api/mesh/link"), params: parame) { responseObject, error in
            
            if error == nil {
                
                success(responseObject as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func checkVersion(type: String, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        KLMNetworking.httpMethod(method: .get, URLString: KLMUrl("api/file/latestVersion/\(type)"), params: nil) { responseObject, error in
            
            if error == nil {
                
                let model = try? JSONDecoder().decode(KLMVersion.self, from: responseObject!)
                let data = model?.data
                success(data as AnyObject)
                
            } else {
                failure(error!)
            }
        }
    }
    
    static func downLoadFile(id: Int, success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
                
        KLMNetworking.httpMethod(method: .downLoad, URLString: KLMUrl("api/file/download/\(id)"), params: nil) { responseObject, error in

            if error == nil {

                success(responseObject as AnyObject)

            } else {
                failure(error!)
            }
        }
    }
    
    static func checkAppVersion(success: @escaping KLMResponseSuccess, failure: @escaping KLMResponseFailure) {
        
        //查询版本
        KLMNetworking.jsonManagerWithHeader(head: nil).post("https://itunes.apple.com/lookup?id=\(AppleStoreID)", parameters: nil, progress: nil) { task, responseObject in
            
            KLMLog("查询成功:\(responseObject)")
            guard let dic: [String: AnyObject] = responseObject as? [String : AnyObject], dic["resultCount"] as? Int == 1 else {
                return
            }
            
            guard let results: [AnyObject] = dic["results"] as? [AnyObject], let resultFirst: [String : AnyObject] = results.first as? [String : AnyObject], let newVersion = resultFirst["version"] else { return  }
            
            KLMLog("newVersion = \(newVersion)")
            success(newVersion)
            
        } failure: { task, error in
            
            KLMLog("查询失败:\(error)")
            let resultDic = ["error": error.localizedDescription]
            let error = NSError.init(domain: "", code: -1, userInfo: resultDic as [String : Any])
            failure(error)
        }
    }
}
