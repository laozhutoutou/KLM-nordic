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
    
    var myview: OpenGLView20!
    var yuvData: NSData!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("checkUpdate")
        iconImageView.layer.cornerRadius = 16
        iconImageView.clipsToBounds = true
        versionLab.text = String(format: "%@: %@", LANGLOC("version"),KLM_APP_VERSION as! String)
        
        updateBtn.layer.cornerRadius = updateBtn.height / 2
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
    }

    @IBAction func updateClick(_ sender: Any) {
        
        KLMService.checkVersion(type: "bluetooth") { response in
            
        } failure: { error in
            
        }
        
//        KLMService.downLoadFile(id: 1) { response in
//
//        } failure: { error in
//
//        }

        
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
