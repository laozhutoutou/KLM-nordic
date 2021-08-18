//
//  KLMAPPUpdateViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/7.
//

import UIKit

class KLMAPPUpdateViewController: UIViewController {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var versionLab: UILabel!
    @IBOutlet weak var updateBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("checkUpdate")
        iconImageView.layer.cornerRadius = 16
        iconImageView.clipsToBounds = true
        versionLab.text = String(format: "%@: %@", LANGLOC("version"),KLM_APP_VERSION as! String)
        
        updateBtn.layer.cornerRadius = updateBtn.height / 2
    }

    @IBAction func updateClick(_ sender: Any) {
        
        //查询版本
//        KLMNetworking.ShareInstance.POST(URLString: "https://itunes.apple.com/lookup?id=1579633878", params: nil) { response in
//            
//        } failure: { error in
//            
//            KLMShowError(error)
//        }
    }
}
