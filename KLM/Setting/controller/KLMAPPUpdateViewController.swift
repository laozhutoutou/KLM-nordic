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
    
    var myview: OpenGLView20!
    var yuvData: NSData!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LANGLOC("checkUpdate")
        iconImageView.layer.cornerRadius = 16
        iconImageView.clipsToBounds = true
        versionLab.text = String(format: "%@: %@", LANGLOC("version"),KLM_APP_VERSION as! String)
        
        updateBtn.layer.cornerRadius = updateBtn.height / 2
        
        if let path = Bundle.main.path(forResource: "jpgimage1_image_640_480", ofType: "yuv"){
            yuvData = NSData.init(contentsOfFile: path)

            self.myview = OpenGLView20.init(frame: CGRect.init(x: 20, y: 20, width: KLMScreenW - 40, height: 550))
            self.view.addSubview(self.myview)

        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        self.myview.setVideoSize(640, height: 480)
        self.myview.displayYUV420pData(self.yuvData as Data?, width: 640, height: 480)
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
