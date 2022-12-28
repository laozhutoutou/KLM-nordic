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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("App update")
        iconImageView.layer.cornerRadius = 16
        iconImageView.clipsToBounds = true
        versionLab.text = String(format: "%@: %@", LANGLOC("Version"),KLM_APP_VERSION as! String)
        
        let appName: String = KLM_APP_NAME as! String
        nameLab.text = appName
        
        updateBtn.layer.cornerRadius = updateBtn.height / 2
        updateBtn.backgroundColor = appMainThemeColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActive), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        updateBtn.setTitle(LANGLOC("Upgrade the app"), for: .normal)
        
    }
    
    @objc func applicationBecomeActive() {
        
        versionLab.text = String(format: "%@: %@", LANGLOC("Version"),KLM_APP_VERSION as! String)
    }
    
    @IBAction func updateClick(_ sender: Any) {
        
        if apptype == .test {
            SVProgressHUD.showInfo(withStatus: "app没上架市场，无法更新。")
            return
        }
        
        ///检查版本
        if apptype == .targetGN || apptype == .targetsGW {
            checkAPPVersion()
        }
        
        if apptype == .targetSensetrack {
            checkAppleStoreVersion()
        }
    }
    
    private func checkAPPVersion() {
        
        SVProgressHUD.show()
        KLMService.checkAPPVersion { response in
            SVProgressHUD.dismiss()
            guard let versionData = response as? KLMVersion.KLMVersionData else { return  }
            let currentVersion = String(format: "%@", KLM_APP_VERSION as! String)
            
            guard currentVersion.compare(versionData.fileVersion) == .orderedAscending else { //左操作数小于右操作数，需要升级
                SVProgressHUD.showInfo(withStatus: LANGLOC("Latest version"))
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
    }
    
    private func checkAppleStoreVersion() {
        
        SVProgressHUD.show()
        KLMService.checkAppleStoreAppVersion { response in
            SVProgressHUD.dismiss()
            guard let newVersion = response as? String else { return  }
            let currentVersion = String(format: "%@", KLM_APP_VERSION as! String)
            
            guard currentVersion.compare(newVersion) == .orderedAscending else { //左操作数小于右操作数，需要升级
                SVProgressHUD.showInfo(withStatus: LANGLOC("Latest version"))
                return
            }
                        
            ///跳转到appleStore
            let url: String = "http://itunes.apple.com/app/id\(AppleStoreID)?mt=8"
            if UIApplication.shared.canOpenURL(URL.init(string: url)!) {
                UIApplication.shared.open(URL.init(string: url)!, options: [:], completionHandler: nil)
            }
            
        } failure: { error in
            SVProgressHUD.showInfo(withStatus: error.localizedDescription)
        }
    }
}
