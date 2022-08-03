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

class KLMPicDownloadViewController: UIViewController {
    
    @IBOutlet weak var SSIDField: UITextField!
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var downLoadBtn: UIButton!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var selectwifiBtn: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    var player: AVPlayer?
    var palyerItem: AVPlayerItem?
    
    deinit {
        palyerItem?.removeObserver(self, forKeyPath: "status", context: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        imageView.isHidden = true
        
        navigationItem.title = LANGLOC("View commodity position")
        selectwifiBtn.backgroundColor = .lightGray.withAlphaComponent(0.5)
        selectwifiBtn.layer.cornerRadius = selectwifiBtn.height/2
        
        ///填充WIFI信息
        if let result = KLMHomeManager.getWIFIMsg() {
            
            SSIDField.text = result.SSID
            passField.text = result.password
        } else {
            
            let ssid = KLMLocationManager.getCurrentWifiName()
            SSIDField.text = ssid
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        //测试
//        let ip: String = "http://pgcvideo-cdn.xiaodutv.com/2709512979_3389490478_20200109153928.mp4?Cache-Control%3Dmax-age%3A8640000%26responseExpires%3DSat%2C_18_Apr_2020_15%3A40%3A20_GMT=&xcode=21958c342f4ee6c4584ce06d904dbb55b291ad05a60eb995&time=1659174959&_=1659091697264"
//        KLMLog("ip = \(ip)")
//        let url = URL.init(string: ip)
//        if player == nil, let url = url {
//            let playerItem = AVPlayerItem.init(url: url)
//            playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
//            player = AVPlayer.init(playerItem: playerItem)
//            self.palyerItem = playerItem
//            player?.rate = 1.0
//            let playerLayer = AVPlayerLayer.init(player: player)
//            playerLayer.videoGravity = .resizeAspect
//            playerLayer.frame = playView.bounds
//            playView.layer.addSublayer(playerLayer)
//            player?.play()
//        }
        
    }

    @IBAction func downLoad(_ sender: Any) {
        
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
                    SVProgressHUD.showInfo(withStatus: LANGLOC("connectFailure"))
                    return
                }
                if ssid == self.SSIDField.text { //加入了WiFi
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
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            switch self.palyerItem!.status{
            case .readyToPlay:
                //准备播放
                KLMLog("准备播放")
            case .failed:
                //播放失败
                KLMLog("播放失败")
                KLMLog("error = \(self.palyerItem?.error)")
            case.unknown:
                //未知情况
                KLMLog("未知错误")
                KLMLog("error = \(self.palyerItem?.error)")
            default:
                break
            }
        }
    }
}

extension KLMPicDownloadViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp == .cameraPic{
            KLMHomeManager.cacheWIFIMsg(SSID: self.SSIDField.text!, password: self.passField.text!)
            let model = KLMWiFiModel.init(WiFiName: self.SSIDField.text!, WiFiPass: self.passField.text!)
            KLMWiFiManager.saveWiFiName(wifiModel: model)
            
            if let data = message?.value as? [UInt8], data.count >= 4 {
                //bmp_stream
                let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp"
//                let ip: String = "http://pgcvideo-cdn.xiaodutv.com/2709512979_3389490478_20200109153928.mp4?Cache-Control%3Dmax-age%3A8640000%26responseExpires%3DSat%2C_18_Apr_2020_15%3A40%3A20_GMT=&xcode=21958c342f4ee6c4584ce06d904dbb55b291ad05a60eb995&time=1659174959&_=1659091697264"
                KLMLog("ip = \(ip)")
                let url = URL.init(string: ip)
//                if player == nil, let url = url {
//                    let playerItem = AVPlayerItem.init(url: url)
//                    playerItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
//                    player = AVPlayer.init(playerItem: playerItem)
//                    self.palyerItem = playerItem
//                    player?.rate = 1.0
//                    let playerLayer = AVPlayerLayer.init(player: player)
//                    playerLayer.videoGravity = .resizeAspect
//                    playerLayer.frame = playView.bounds
//                    playView.layer.addSublayer(playerLayer)
//                    player?.play()
//                }
                /// forceRefresh 不需要缓存
                /// 逆时针90度
                imageView.transform = CGAffineTransform(rotationAngle: CGFloat(-Float.pi / 2))
                imageView.kf.indicatorType = .activity
                ///forceRefresh
                imageView.kf.setImage(with: url, placeholder: nil, options: nil) { result in

                    switch result {
                    case .success(let value):
                        // The image was set to image view:
                        print(value.image)

                    case .failure(let error):
                        KLMLog("error = \(error)") // The error happens
                        if error.errorCode ==  1002 {
                            SVProgressHUD.showInfo(withStatus: LANGLOC("Request timed out."))
                            return
                        }
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
                            let cancelAction = UIAlertAction(title: LANGLOC("cancel"), style: .cancel, handler: nil)
                            alertController.addAction(cancelAction)
                            alertController.addAction(settingsAction)
                            KLMKeyWindow?.rootViewController?.present(alertController, animated: true)
                            return
                        }
                        SVProgressHUD.showInfo(withStatus: error.errorDescription)
                        SVProgressHUD.dismiss(withDelay: 5)
                    }
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
