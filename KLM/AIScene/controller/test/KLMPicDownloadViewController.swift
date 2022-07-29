//
//  KLMPicDownloadViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/25.
//

import UIKit
import RxSwift
import RxCocoa
import NetworkExtension
import SystemConfiguration

class KLMPicDownloadViewController: UIViewController {
    
    @IBOutlet weak var SSIDField: UITextField!
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var downLoadBtn: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("View Commodity Image")
        
        ///填充WIFI信息
        if let result = KLMHomeManager.getWIFIMsg() {
            
            SSIDField.text = result.SSID
            passField.text = result.password
        }

        Observable.combineLatest(SSIDField.rx.text.orEmpty, passField.rx.text.orEmpty) {ssidText, passwordText  in
            
            if ssidText.isEmpty || passwordText.isEmpty{
                return false
            } else {
                return true
            }
        }.bind(to: downLoadBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        //弹出定位弹框
        KLMLocationManager.shared.getLocation {
            
        } failure: {
            
        }
    }

    @IBAction func downLoad(_ sender: Any) {
        
        KLMLocationManager.shared.getLocation {
            
            //定位授权
            self.apply()
            
        } failure: {
            
        }
    }
    
    //APP连接WiFi
    private func apply() {
        
        SVProgressHUD.show(withStatus: LANGLOC("Connecting"))
        let hotspotConfig = NEHotspotConfiguration.init(ssid: SSIDField.text!, passphrase: passField.text!, isWEP: false)
        NEHotspotConfigurationManager.shared.apply(hotspotConfig) { error in
            KLMLog(error)
            if error == nil { //加入和无法加入都返回nil
                let ssid = KLMLocationManager.getCurrentWifiName()
                guard let ssid = ssid else {
                    SVProgressHUD.showInfo(withStatus: LANGLOC("connectFailure"))
                    return
                }
                if ssid == self.SSIDField.text { //加入了WiFi
                    KLMHomeManager.cacheWIFIMsg(SSID: self.SSIDField.text!, password: self.passField.text!)
                    KLMLog("入网成功")
                    self.sendWIfiMesssage()
                } else {
                    SVProgressHUD.showInfo(withStatus: LANGLOC("connectFailure"))
                }
            } else {
                if let err = error as? NSError {
                    if err.code == NEHotspotConfigurationError.alreadyAssociated.rawValue { //当前连接的WiFi
                        KLMLog("是当前连接的WiFi")
                        self.sendWIfiMesssage()
                    } else {
                        SVProgressHUD.showInfo(withStatus: err.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func sendWIfiMesssage() {
        
        KLMLog("发送WiFi信息给设备")
        SVProgressHUD.show(withStatus: LANGLOC("Send the WiFi information to the device"))
        let urlSSID: String = self.SSIDField.text!
        let urlPassword: String = self.passField.text!
        
        //32
        var urlSSIDBytes: [UInt8] = [UInt8](urlSSID.data(using: String.Encoding.ascii)!)
        urlSSIDBytes = urlSSIDBytes + [UInt8].init(repeating: 0, count: 32 - urlSSIDBytes.count)
        //32
        var urlPasswordBytes: [UInt8] = [UInt8](urlPassword.data(using: String.Encoding.ascii)!)
        urlPasswordBytes = urlPasswordBytes + [UInt8].init(repeating: 0, count: 32 - urlPasswordBytes.count)
        
        let parameters = Data.init(bytes: (urlSSIDBytes + urlPasswordBytes), count: (urlSSIDBytes + urlPasswordBytes).count)
        let allBytes: String = parameters.hex
        let parame = parameModel(dp: .cameraPic, value: allBytes)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMPicDownloadViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp == .cameraPic{
            KLMHomeManager.cacheWIFIMsg(SSID: self.SSIDField.text!, password: self.passField.text!)
            if let data = message?.value as? [UInt8], data.count >= 4 {
                
                let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp"
                KLMLog("ip = \(ip)")
                let url = URL.init(string: ip)
                                
                /// forceRefresh 不需要缓存
                /// 逆时针90度
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat(-Float.pi / 2))
                imageView.kf.indicatorType = .activity
                imageView.kf.setImage(with: url, placeholder: nil, options: [.forceRefresh]) { result in

                    switch result {
                    case .success(let value):
                        // The image was set to image view:
                        print(value.image)
                        
                        ///测试使用 - 保存图片到相册
//                        SVProgressHUD.show(withStatus: "保存到手机")
//                        let data: Data = try! Data.init(contentsOf: url!)
//                        let image: UIImage = UIImage.init(data: data)!
//                        UIImageWriteToSavedPhotosAlbum(value.image, self, #selector(self.saveImage(image:didFinishSavingWithError:contextInfo:)), nil)

                    case .failure(let error):
                        KLMLog("error = \(error)") // The error happens
                        //检查本地网络情况
                        let alertController = UIAlertController(title: LANGLOC("Local Network permissions"), message: LANGLOC("Please check whether the Local Network permissions is turned on?"), preferredStyle: .alert)
                        let settingsAction = UIAlertAction(title: LANGLOC("Settings"), style: .default) { (_) -> Void in
                            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                            }
                        }
                        let cancelAction = UIAlertAction(title: LANGLOC("cancel"), style: .default, handler: nil)
                        alertController.addAction(cancelAction)
                        alertController.addAction(settingsAction)
                        KLMKeyWindow?.rootViewController?.present(alertController, animated: true)
                        
                    }
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
