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
    @IBOutlet weak var downLoadBtn: UIButton!
    @IBOutlet weak var playView: UIView!
    @IBOutlet weak var selectwifiBtn: UIButton!
    
    var webView: WKWebView?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
}

extension KLMPicDownloadViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp == .cameraPic{
            KLMHomeManager.cacheWIFIMsg(SSID: self.SSIDField.text!, password: self.passField.text!)
            let model = KLMWiFiModel.init(WiFiName: self.SSIDField.text!, WiFiPass: self.passField.text!)
            KLMWiFiManager.saveWiFiName(wifiModel: model)
            
            if let data = message?.value as? [UInt8], data.count >= 4 {
                //bmp_stream  stream
                let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp_stream"
                KLMLog("ip = \(ip)")
                let url = URL.init(string: ip)
                if webView == nil {
                    webView = WKWebView.init()
                    webView?.frame = playView.bounds
                    playView.addSubview(webView!)
                    webView?.navigationDelegate = self
                }
                webView?.showEmptyView()
                let request = URLRequest(url: url!)
                webView?.load(request)
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMPicDownloadViewController: WKNavigationDelegate {
    
//    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//
//        KLMLog("type = \(String(describing: navigationResponse.response.mimeType)), fileName = \(String(describing: navigationResponse.response.suggestedFilename))")
//        decisionHandler(.download)
//    }
    
    //页面开始加载时调用
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        KLMLog("开始加载")
    }
    //当内容开始返回时调用
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webView.hideEmptyView()
        KLMLog("内容返回")
    }
    
    // 页面加载完成之后调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        KLMLog("加载完成")
    }
    
    //页面加载失败时调用
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.hideEmptyView()
        SVProgressHUD.showInfo(withStatus: error.localizedDescription)
        SVProgressHUD.dismiss(withDelay: 3)
        KLMLog("页面加载失败\(error)")
    }
}

