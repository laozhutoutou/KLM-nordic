//
//  KLMLocationManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/25.
//

import Foundation
import CoreLocation

class KLMLocationManager: NSObject {
    
    typealias SuccessBlock = () -> Void
    typealias FailureBlock = () -> Void
    
    var successBlock: SuccessBlock?
    var failureBlock: FailureBlock?
    
    lazy var locaionManager: CLLocationManager = {
        let locaionManager = CLLocationManager()
        return locaionManager
    }()
    
    func getLocation(_ success: @escaping SuccessBlock, failure: @escaping FailureBlock) {
        successBlock = success
        failureBlock = failure
        
        var status: CLAuthorizationStatus?
        if #available(iOS 14.0, *) {
            status = locaionManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        switch status {
        case .authorizedWhenInUse,
                .authorizedAlways:
            KLMLog("定位已经授权")
            successBlock?()
        case .notDetermined:
            KLMLog("尚未设置定位")
            locaionManager.requestWhenInUseAuthorization()
            locaionManager.delegate = self

        case .denied,
                .restricted:
            KLMLog("用户拒绝")
            failureBlock?()
            show()
        default:
            break
        }
    }
    
    private func show() {
        
        let alertController = UIAlertController(title: LANGLOC("Location permission"), message: LANGLOC("Please go to Settings and turn on the permissions"), preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: LANGLOC("Settings"), style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
            }
        }
        let cancelAction = UIAlertAction(title: LANGLOC("cancel"), style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        KLMKeyWindow?.rootViewController?.present(alertController, animated: true)
    }
    
    //获取当前连接的WiFi
    static func getCurrentWifiName() -> String? {
        var wifiName : String = ""
        let wifiInterfaces = CNCopySupportedInterfaces()
        if wifiInterfaces == nil {
            return nil
        }
        
        let interfaceArr = CFBridgingRetain(wifiInterfaces!) as! Array<String>
        if interfaceArr.count > 0 {
            let interfaceName = interfaceArr[0] as CFString
            let ussafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName)
            
            if (ussafeInterfaceData != nil) {
                let interfaceData = ussafeInterfaceData as! Dictionary<String, Any>
                wifiName = interfaceData["SSID"]! as! String
            }
        }
        
        return wifiName
    }
    
    static let shared = KLMLocationManager()
    private override init(){}
}

extension KLMLocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .authorizedWhenInUse,
                .authorizedAlways:
            KLMLog("定位已经授权")
            successBlock?()
        case .notDetermined:
            KLMLog("尚未设置定位")
            
        case .denied,
                .restricted:
            KLMLog("用户拒绝")
            failureBlock?()
        
        default:
            break
        }
    }
}
