//
//  KLMAPPUpdateViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/7.
//

import UIKit
import SSZipArchive
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
        
        KLMService.checkAppVersion { response in
            
            let newVersion: String = response as! String
            let currentVersion: String = String(format: "%@", KLM_APP_VERSION as! String)
            
            let value = currentVersion.compare(newVersion)
            if value == .orderedAscending {//左操作数小于右操作数，需要升级
                
                ///跳转到appleStore
                let url: String = "http://itunes.apple.com/app/id\(AppleStoreID)?mt=8"
                if UIApplication.shared.canOpenURL(URL.init(string: url)!) {
                    UIApplication.shared.open(URL.init(string: url)!, options: [:], completionHandler: nil)
                }
                
            } else {
                
                SVProgressHUD.showInfo(withStatus: LANGLOC("DFUVersionTip"))
            }
            
        } failure: { error in
            
            KLMLog("查询失败:\(error)")
            var err = MessageError()
            err.message = error.localizedDescription
            KLMShowError(err)
        }
        
        ///解压文件
//        let path = Bundle.main.path(forResource: "Project", ofType: "zip")
//        let des = NSHomeDirectory() + "/Documents/Project"
//        SSZipArchive.unzipFile(atPath: path!, toDestination: des) { str, info, index, index1 in
//            print(str)
//            print(info)
//            print(index)
//            print(index1)
//        } completionHandler: { str, bool, error in
//            print(bool)
//            print(error)
//        }
//
//        ///获取文件
//        let filePath = NSHomeDirectory() + "/Documents/Project/Project.bin"
//        if FileManager.default.fileExists(atPath: filePath){
//            let data = NSData.init(contentsOfFile: filePath)
//            KLMLog(data)
//        }
    }
}
