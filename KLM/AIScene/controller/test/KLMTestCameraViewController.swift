//
//  KLMTestCameraViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/9.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision
import SVProgressHUD
import Kingfisher

class KLMTestCameraViewController: UIViewController {
    
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
          
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        
    }
    
    @IBAction func downLoad(_ sender: Any) {
                
        SVProgressHUD.show()
        let parameTime = parameModel(dp: .cameraPic)
        KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMTestCameraViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp == .cameraPic{
            
            if let data = message?.value as? [UInt8], data.count >= 4 {
                
                let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp"
                KLMLog("ip = \(ip)")
                ipTextField.text = ip
                let url = URL.init(string: ip)
                
                /// forceRefresh 不需要缓存
                imageView.kf.indicatorType = .activity
//                imageView.kf.setImage(with: url, placeholder: nil, options: [.forceRefresh])
                
                imageView.kf.setImage(with: url, placeholder: nil, options: [.forceRefresh]) { result in

                    switch result {
                    case .success(let value):
                        // The image was set to image view:
                        print(value.image)

                        ///测试使用 - 保存图片到相册
                        SVProgressHUD.show(withStatus: "保存到手机")
//                        let data: Data = try! Data.init(contentsOf: url!)
//                        let image: UIImage = UIImage.init(data: data)!
                        UIImageWriteToSavedPhotosAlbum(value.image, self, #selector(self.saveImage(image:didFinishSavingWithError:contextInfo:)), nil)

                    case .failure(let error):
                        print(error) // The error happens
                    }
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
        
    }
    
    @objc private func saveImage(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
            var showMessage = ""
            if error != nil{
                showMessage = "保存失败"
            }else{
                showMessage = "保存成功"
            }
            SVProgressHUD.showInfo(withStatus: showMessage)
            
        }
}

