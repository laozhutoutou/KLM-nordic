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
            
            let appName: String = KLM_APP_NAME as! String
            let alertController = UIAlertController(title: nil, message: "Allow" +  appName + "to access your camera on Settings-privacy on your iPhone", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Setting", style: .default, handler: {_ in
                
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
