//
//  KLMBlueToothManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/4.
//

import Foundation

class KLMBlueToothManager {

    ///APP蓝牙未授权
   static func showUnauthorizedAlert() {
        
        let alertController = UIAlertController(title: LANGLOC("Bluetooth permission"), message: LANGLOC("Please go to Settings and turn on the permissions"), preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: LANGLOC("Settings"), style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
            }
        }
        let cancelAction = UIAlertAction(title: LANGLOC("Cancel"), style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        KLMKeyWindow?.rootViewController?.present(alertController, animated: true)
    }
}
