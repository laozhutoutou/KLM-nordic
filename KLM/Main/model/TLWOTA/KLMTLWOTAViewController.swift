//
//  KLMTLWOTAViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/9/22.
//

import UIKit

class KLMTLWOTAViewController: UIViewController {
    
    @IBOutlet weak var tipLab: UILabel!
    @IBOutlet weak var upgradeBtn: UIButton!
    
    var BLEVersionData: KLMVersion.KLMVersionData?
    var isPresent: Bool = false
    
    ///更新包
    var OTAData: NSData?
    
    deinit {
        OTAManager.shared.close()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        OTAManager.shared.close()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tipLab.text = LANGLOC("Please do not move the mobile phone. and keep the Bluetooth connection between the mobile phone and the light during the update process.")
        
        //导航栏左边添加返回按钮
        if isPresent {
            navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(dimiss)) as? [UIBarButtonItem]
        }
    
        self.downLoad()
    }
    
    func downLoad() {
        
        SVProgressHUD.show(withStatus: LANGLOC("Downloading"))
        KLMService.downLoadFile(id: BLEVersionData!.id) { response in
            SVProgressHUD.showInfo(withStatus: LANGLOC("Success"))
            let data: NSData = response as! NSData
            KLMLog("data = \(data.count)")
            self.OTAData = data
            
        } failure: { error in
            KLMHttpShowError(error)
        }
    }

    @IBAction func upgrade(_ sender: Any) {
        
        guard let data = OTAData else {
            
            SVProgressHUD.showInfo(withStatus: LANGLOC("Failed to get update package"))
            return
            
        }
        
        SVProgressHUD.show()
        let result = OTAManager.shared.startOTAWithOtaData(data: data, node: KLMHomeManager.currentNode) {[weak self] in
            guard let self = self else {return }
            self.otaSuccessAction()
            
        } failAction: {
            self.otaFailAction()
        } progressAction: { progress in
            self.showOTAProgress(progress: progress)
        }
        KLMLog("result = \(result)")
    }
    
    private func otaSuccessAction() {
        KLMLog("OTA success")
        SVProgressHUD.showSuccess(withStatus: LANGLOC("Updatecomplete"))
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            if self.isPresent {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func otaFailAction() {
        KLMLog("OTA fail")
        SVProgressHUD.showInfo(withStatus: "OTA fail")
    }
    
    private func showOTAProgress(progress: Float) {
        KLMLog("progress = \(Int(progress))")
        let pp: Float = progress / 100.0
        SVProgressHUD.showProgress(pp, status: "\(Int(pp * 100))" + "%")
        if progress == 100 {
            SVProgressHUD.show(withStatus: LANGLOC("Restarting"))
        }
    }
    
    @objc func dimiss() {
        
        dismiss(animated: true, completion: nil)
    }
}
