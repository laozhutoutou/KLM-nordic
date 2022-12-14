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
import SwiftUI
import AVFoundation
import WebKit

class KLMPicDownloadViewController: UIViewController {
    
    @IBOutlet weak var SSIDField: UITextField!
    @IBOutlet weak var passField: UITextField!
    ///下载按钮
    @IBOutlet weak var downLoadBtn: UIButton!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var selectwifiBtn: UIButton!
    ///图片
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var WifiNameLab: UILabel!
    @IBOutlet weak var passwordLab: UILabel!

    
    var webView: WKWebView?
    lazy var wkConfig: WKWebViewConfiguration = {
        let wkConfig = WKWebViewConfiguration.init()
        let jScript = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'); document.getElementsByTagName('head')[0].appendChild(meta);"
        let wkUScript = WKUserScript.init(source: jScript, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
        let wkUController = WKUserContentController.init()
        wkUController.addUserScript(wkUScript)
        wkConfig.userContentController = wkUController
        return wkConfig
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        imageView.isHidden = true
        
        //        playView.transform = CGAffineTransform(rotationAngle:  -CGFloat.pi / 2)
        
        navigationItem.title = LANGLOC("View commodity position")
        selectwifiBtn.backgroundColor = .lightGray.withAlphaComponent(0.1)
        selectwifiBtn.layer.cornerRadius = selectwifiBtn.height/2
        selectwifiBtn.setTitleColor(appMainThemeColor, for: .normal)
        downLoadBtn.layer.cornerRadius = downLoadBtn.height / 2
        downLoadBtn.backgroundColor = appMainThemeColor
        
        ///填充WIFI信息
        if let result = KLMHomeManager.getWIFIMsg() {
            
            SSIDField.text = result.SSID
            passField.text = result.password
        } else {
            
            let ssid = KLMLocationManager.getCurrentWifiName()
            SSIDField.text = ssid
        }
        
        //弹出定位弹框
        KLMLocationManager.shared.getLocation {
            if KLMTool.isEmptyString(string: self.SSIDField.text) == nil {
                
                let ssid = KLMLocationManager.getCurrentWifiName()
                self.SSIDField.text = ssid
            }
        } failure: {
            
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        WifiNameLab.text = LANGLOC("Wi-Fi")
        SSIDField.placeholder = LANGLOC("Please enter the Wi-Fi")
        selectwifiBtn.setTitle(LANGLOC("Select Wi-Fi networks"), for: .normal)
        passwordLab.text = LANGLOC("Password")
        passField.placeholder = LANGLOC("Please enter the password")
        downLoadBtn.setTitle(LANGLOC("View"), for: .normal)
       
    }
    
    @IBAction func downLoad(_ sender: Any) {
        
        ///页面加载中，同时WiFi名称没改变，需要再加载
        //        if let webView = webView {
        //            if webView.isLoading && oldWifiName == self.SSIDField.text{
        //                SVProgressHUD.showInfo(withStatus: LANGLOC(""))
        //                return
        //            }
        //        }
        
        if KLMTool.isEmptyString(string: SSIDField.text) == nil || KLMTool.isEmptyString(string: passField.text) == nil {
            
            return
        }
        
        KLMLocationManager.shared.getLocation {
            
            //定位授权
            self.apply()
            
        } failure: {
            
        }
    }
    
    @IBAction func selectWifi(_ sender: Any) {
        
        KLMLocationManager.shared.getLocation {
            
            //弹框
            let vc = KLMWifiSelectViewController()
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.wifiBlock = {[weak self] model in
                guard let self = self else { return  }
                self.SSIDField.text = model.WiFiName
                self.passField.text = model.WiFiPass
                
            }
            self.present(vc, animated: true)
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
                    SVProgressHUD.showInfo(withStatus: LANGLOC("Connect failure"))
                    return
                }
                if ssid == self.SSIDField.text { //加入了WiFi
                    KLMLog("入网成功")
                    self.sendWIfiMesssage()
                } else {
                    SVProgressHUD.showInfo(withStatus: LANGLOC("Connect failure"))
                }
            } else {
                if let err = error as? NSError {
                    if err.code == NEHotspotConfigurationError.alreadyAssociated.rawValue { //当前连接的WiFi
                        KLMLog("是当前连接的WiFi")
                        self.sendWIfiMesssage()
                    } else if err.code == NEHotspotConfigurationError.invalidWPAPassphrase.rawValue {
                        SVProgressHUD.showInfo(withStatus: LANGLOC("Password error"))
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
        var urlSSIDBytes: [UInt8] = [UInt8](urlSSID.data(using: .utf8)!)
        urlSSIDBytes = urlSSIDBytes + [UInt8].init(repeating: 0, count: 32 - urlSSIDBytes.count)
        //32
        var urlPasswordBytes: [UInt8] = [UInt8](urlPassword.data(using: .utf8)!)
        urlPasswordBytes = urlPasswordBytes + [UInt8].init(repeating: 0, count: 32 - urlPasswordBytes.count)
        
        let parameters = Data.init(bytes: (urlSSIDBytes + urlPasswordBytes), count: (urlSSIDBytes + urlPasswordBytes).count)
        let allBytes: String = parameters.hex
        let parame = parameModel(dp: .cameraPic, value: allBytes)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @objc func appWillEnterForeground(){
        KLMLog("周期 ---将进入前台通知")
        //获取WiFi
        if let ssid = KLMLocationManager.getCurrentWifiName() {
            self.SSIDField.text = ssid
            if let wifilist = KLMWiFiManager.getWifiLists(), let model = wifilist.first(where: {$0.WiFiName == ssid}) {
                self.passField.text = model.WiFiPass
            }
        }
    }
    
    
    @objc func saveImage(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        
        if error == nil {
            SVProgressHUD.showSuccess(withStatus: "保存成功")
            return
        }
        SVProgressHUD.showError(withStatus: "保存失败")
    }
}

extension KLMPicDownloadViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp == .cameraPic{
            KLMHomeManager.cacheWIFIMsg(SSID: self.SSIDField.text!, password: self.passField.text!)
            let model = KLMWiFiModel.init(WiFiName: self.SSIDField.text!, WiFiPass: self.passField.text!)
            KLMWiFiManager.saveWiFiName(wifiModel: model)
            
            //            oldWifiName = SSIDField.text
            if let data = message?.value as? [UInt8], data.count >= 4 {
                //bmp_stream视频  bmp
                let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp"
                KLMLog("ip = \(ip)")
                let url = URL.init(string: ip)
                
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat(-Float.pi / 2))
                imageView.kf.indicatorType = .activity
                imageView.kf.setImage(with: url, placeholder: nil, options: [.forceRefresh]) { result in
                    
                    switch result {
                    case .success(let value):
                        // The image was set to image view:
                        print(value.image)
//                        SVProgressHUD.show(withStatus: "保存...")
//                        let data: Data = try! Data.init(contentsOf: url!)
//                        let image: UIImage = UIImage.init(data: data)!
//                        UIImageWriteToSavedPhotosAlbum(value.image, self, #selector(self.saveImage(image:didFinishSavingWithError:contextInfo:)), nil)
                        
                        
                    case .failure(let error):
                        KLMLog("error = \(error)") // The error happens
                        if error.errorCode == 1001 {
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
                            let cancelAction = UIAlertAction(title: LANGLOC("Cancel"), style: .default, handler: nil)
                            alertController.addAction(cancelAction)
                            alertController.addAction(settingsAction)
                            KLMKeyWindow?.rootViewController?.present(alertController, animated: true)
                            return
                        }
                        SVProgressHUD.showInfo(withStatus: error.localizedDescription)
                        SVProgressHUD.dismiss(withDelay: 3)
                    }
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
    
    
}


