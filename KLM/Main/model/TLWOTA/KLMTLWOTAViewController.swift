//
//  KLMTLWOTAViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/9/22.
//

import UIKit

class KLMTLWOTAViewController: UIViewController {
    
    var BLEVersionData: KLMVersion.KLMVersionData?
    
    deinit {
        OTAManager.shared.close()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        OTAManager.shared.close()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        KLMService.checkTLWVersion { response in
            
            self.BLEVersionData = response as? KLMVersion.KLMVersionData
            self.downLoad()
            
        } failure: { error in
            
        }
    }
    
    func downLoad() {
        
        KLMService.downLoadFile(id: BLEVersionData!.id) { response in
            
            let data: Data = response as! Data
            KLMLog("data = \(data.count)")
            
        } failure: { error in
            
        }
    }

    @IBAction func upgrade(_ sender: Any) {
        
        guard let path = Bundle.main.path(forResource: "bleota", ofType: "bin") else { return }
        let data = NSData.init(contentsOfFile: path)
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
    }
    private func otaFailAction() {
        KLMLog("OTA fail")
    }
    private func showOTAProgress(progress: Float) {
        let pp: Int = Int(progress)
        KLMLog("progress = \(pp)")
    }
}
