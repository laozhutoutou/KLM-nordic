//
//  KLMPCBASensorViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/31.
//

import UIKit
import WebKit

class KLMPCBASensorViewController: UIViewController {
    
    @IBOutlet weak var WWOK: UIButton!
    @IBOutlet weak var ROK: UIButton!
    @IBOutlet weak var GOK: UIButton!
    @IBOutlet weak var BOK: UIButton!
    @IBOutlet weak var stanbyOK: UIButton!
    
    @IBOutlet weak var OKBtn: UIButton!
    @IBOutlet weak var falseBtn: UIButton!
    
    @IBOutlet weak var playView: UIView!
    var webView: WKWebView?
    
    var OKBtnArray: [UIButton]!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "sensor测试"

        OKBtnArray = [WWOK,ROK,GOK,BOK,stanbyOK]
        
        OKBtn.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        falseBtn.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        
        for btn in OKBtnArray {
            btn.isHidden = true
        }
        
    }
    
    @IBAction func startTest(_ sender: Any) {
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0201"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    @IBAction func sensorResult(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        sender.isSelected = true
        if sender.tag == 1 { //OK
            
            falseBtn.isSelected = false
            let string = "0201"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            OKBtn.isSelected = false
            let string = "0200"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
    
    
    @IBAction func stanbyClick(_ sender: Any) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0209"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func downLoadPic(_ sender: Any) {
        
        let parameTime = parameModel(dp: .cameraPic)
        KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMPCBASensorViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "020101" {
                WWOK.isHidden = false
            } else if value == "020102" {
                ROK.isHidden = false
            } else if value == "020103" {
                GOK.isHidden = false
            } else if value == "020104" {
                BOK.isHidden = false
                SVProgressHUD.dismiss()
                
            }
        }
        
        //待机功耗
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "0209"{
                SVProgressHUD.dismiss()
                stanbyOK.isHidden = false
            }
        }
        
        if message?.dp ==  .cameraPic{
            
            if let data = message?.value as? [UInt8], data.count >= 4 {
                
                let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp"
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
        
        //合格或者不合格
        if message?.dp == .factoryTestResule {
//            SVProgressHUD.showSuccess(withStatus: "测试完成")
            //重置节点
            KLMSmartNode.sharedInstacnce.resetNode(node: KLMHomeManager.currentNode)
        }
    }
    
    func smartNodeDidResetNode(_ manager: KLMSmartNode){
        ///提交数据到服务器
        if KLMMesh.save() {
            
        }
        SVProgressHUD.showSuccess(withStatus: "测试完成")
        DispatchQueue.main.asyncAfter(deadline: 0.5) {
            NotificationCenter.default.post(name: .deviceReset, object: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }
        
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMPCBASensorViewController: WKNavigationDelegate {
    
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
