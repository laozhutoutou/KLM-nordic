//
//  KLMNetworking.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/4.
//

import UIKit
import Alamofire

typealias KLMResponseSuccess = (_ response: AnyObject) -> Void
typealias KLMResponseFailure = (_ error: Error) -> Void

class KLMNetworking: NSObject {
    
    
    
    static let ShareInstance = KLMNetworking()
    private override init() {}
    
    private var header: [String: String]? {
        guard let token = KLMGetUserDefault("token") as? String else {
            return nil
        }
        
        return ["Authorization": token]
    }
    
    private lazy var manager: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = header
        configuration.timeoutIntervalForRequest = 10
        return Session.init(configuration: configuration, delegate: SessionDelegate.init(), serverTrustManager: nil)
    }()
    
    func POST(URLString: String,
              params: [String: Any]?,
              success: @escaping KLMResponseSuccess,
              failure: @escaping KLMResponseFailure) {
        
        requestWith(URLString: URLString,
                    httpMethod: 1,
                    params: params,
                    success: success,
                    failure: failure)
    }
    
    func GET(URLString: String,
              params: [String: Any]?,
              success: @escaping KLMResponseSuccess,
              failure: @escaping KLMResponseFailure) {
        
        requestWith(URLString: URLString,
                    httpMethod: 0,
                    params: params,
                    success: success,
                    failure: failure)
    }

    func requestWith(URLString: String,
                            httpMethod: Int32,
                            params: [String: Any]?,
                            success: @escaping KLMResponseSuccess,
                            failure: @escaping KLMResponseFailure) {
        
        if httpMethod == 0 {
            
            manageGet(URLString: URLString, params: params, success: success, failure: failure)
        } else {
            
            managePost(URLString: URLString, params: params, success: success, failure: failure)
        }
    }
    
    func managePost(URLString: String,
                            params: [String: Any]?,
                            success: @escaping KLMResponseSuccess,
                            failure: @escaping KLMResponseFailure) {
        
        
        manager.request(URLString,
                        method: .post,
                        parameters: params,
                        encoding: JSONEncoding.default,
                        headers: nil).responseJSON { (response) in
            
            switch response.result {
            case .success:
                if let value = response.value as? [String: Any]{
                    if value["code"] as? Int == 200 {
                        
                        success(value as AnyObject)
                    }
                }
            case .failure(let error):
                
                let statusCode = response.response?.statusCode
                let errorStr = HTTPURLResponse.localizedString(forStatusCode: statusCode ?? 0)
                KLMLog("error = \(errorStr)")
                failure(error)
            }
            
        }
    }
    
    func manageGet(URLString: String,
                            params: [String: Any]?,
                            success: @escaping KLMResponseSuccess,
                            failure: @escaping KLMResponseFailure) {
        manager.request(URLString,
                        method: .get,
                        parameters: params,
                        encoding: JSONEncoding.default,
                        headers: nil).responseJSON { (response) in
            
            switch response.result {
            case .success:
                if let value = response.value as? [String: Any]{
                    if value["code"] as? Int == 200 {
                        
                        success(value as AnyObject)
                    }
                }
            case .failure(let error):
                
                failure(error)
            }
            
        }
    }
}
