//
//  KLMPhotoManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/7.
//

import Foundation
import AVFoundation

class KLMPhotoManager {
    
    var success: (() -> Void)!
    
    func photoAuthStatus(success: @escaping () -> Void) {
        
        self.success = success
        
        AuthStatus()
    }
    
    func AuthStatus() {
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .restricted || authStatus == .denied{
            
            let alertController = UIAlertController(title: "无法使用相机", message: "请在iPhone的"+"设置-隐私-相机"+"中允许访问相机", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "设置", style: .default, handler: {_ in
                
                UIApplication.shared.open(NSURL(string: UIApplication.openSettingsURLString)! as URL, options: [:], completionHandler: nil)
            }))
            KLMKeyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
            
        } else if authStatus == .notDetermined {
            
            AVCaptureDevice.requestAccess(for: .video) { (bool:Bool) in
                
                if bool {
                    DispatchQueue.main.async {
                       
                        self.AuthStatus()
                    }
                }
            }
        } else {
            
            self.success()
        }
    }
}
