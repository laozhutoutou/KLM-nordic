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
import WebKit

class KLMTestCameraViewController: UIViewController {
    
    @IBOutlet weak var ipTextField: UITextField!
    @IBOutlet weak var imageBgView: UIView!
    var webView: WKWebView?
    
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
        let parame = parameModel(dp: .cameraPic)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
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
                if webView == nil {
                    webView = WKWebView.init()
                    webView?.frame = imageBgView.bounds
                    imageBgView.addSubview(webView!)
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

extension KLMTestCameraViewController: WKNavigationDelegate {
    
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
