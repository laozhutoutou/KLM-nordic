//
//  KLMAPPUpdateViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/7.
//

import UIKit
import SwiftUI

class KLMAPPUpdateViewController: UIViewController {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var versionLab: UILabel!
    @IBOutlet weak var updateBtn: UIButton!
    
    @IBOutlet weak var nameLab: UILabel!
    
    var myview: OpenGLView20!
    var yuvData: NSData!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("checkUpdate")
        iconImageView.layer.cornerRadius = 16
        iconImageView.clipsToBounds = true
        versionLab.text = String(format: "%@: %@", LANGLOC("version"),KLM_APP_VERSION as! String)
        
        let appName: String = KLM_APP_NAME as! String
        nameLab.text = appName
        
        updateBtn.layer.cornerRadius = updateBtn.height / 2
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func applicationBecomeActive() {
        
        versionLab.text = String(format: "%@: %@", LANGLOC("Version"),KLM_APP_VERSION as! String)
    }
    
    @IBAction func updateClick(_ sender: Any) {
        
        SVProgressHUD.show()
        KLMService.checkVersion(type: "ios") { response in
            SVProgressHUD.dismiss()
            guard let versionData = response as? KLMVersion.KLMVersionData else { return  }
            let currentVersion = String(format: "%@", KLM_APP_VERSION as! String)
            
            guard currentVersion.compare(versionData.fileVersion) == .orderedAscending else { //左操作数小于右操作数，需要升级
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
                return
            }
            
            ///跳转到appleStore
            let url: String = "http://itunes.apple.com/app/id\(AppleStoreID)?mt=8"
            if UIApplication.shared.canOpenURL(URL.init(string: url)!) {
                UIApplication.shared.open(URL.init(string: url)!, options: [:], completionHandler: nil)
            }
            
            
        } failure: { error in
            KLMHttpShowError(error)
        }
        
//        KLMService.checkAppVersion { response in
//            SVProgressHUD.dismiss()
//            let newVersion: String = response as! String
//            let currentVersion: String = String(format: "%@", KLM_APP_VERSION as! String)
//
//            let value = currentVersion.compare(newVersion)
//            if value == .orderedAscending {//左操作数小于右操作数，需要升级
//
//                ///跳转到appleStore
//                let url: String = "http://itunes.apple.com/app/id\(AppleStoreID)?mt=8"
//                if UIApplication.shared.canOpenURL(URL.init(string: url)!) {
//                    UIApplication.shared.open(URL.init(string: url)!, options: [:], completionHandler: nil)
//                }
//
//            } else {
//
//                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
//            }
//
//        } failure: { error in
            
//            KLMLog("查询失败:\(error)")
//            var err = MessageError()
//            err.message = error.localizedDescription
//            KLMShowError(err)
//        }
        
    }
}
