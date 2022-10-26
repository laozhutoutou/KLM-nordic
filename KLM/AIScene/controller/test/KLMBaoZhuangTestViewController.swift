//
//  KLMBaoZhuangTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/8/31.
//

import UIKit
import WebKit

class KLMBaoZhuangTestViewController: UIViewController {
    
    @IBOutlet weak var WBtn: UIButton!
    @IBOutlet weak var RBtn: UIButton!
    @IBOutlet weak var GBtn: UIButton!
    @IBOutlet weak var BBtn: UIButton!
    
    @IBOutlet weak var oneBtn: UIButton!
    @IBOutlet weak var hundredBtn: UIButton!
    
    @IBOutlet weak var playView: UIView!
    var webView: WKWebView?
    
    @IBOutlet weak var stanbyOK: UIButton!
    @IBOutlet weak var OKBtn: UIButton!
    @IBOutlet weak var falseBtn: UIButton!
    
    var tongdaoBtnArray: [UIButton]!
    var tiaoguangBtnArray: [UIButton]!
    
    var tongdaoValue: Int = 1
    var tiaoguangValue: Int = 1
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "包装测试"
        
        tongdaoBtnArray = [WBtn, RBtn, GBtn, BBtn]
        tiaoguangBtnArray = [oneBtn, hundredBtn]
        
        for btn in tongdaoBtnArray {
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.black.cgColor
            
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            
            btn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
            btn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        }
        
        for btn in tiaoguangBtnArray {
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.black.cgColor
            
            btn.setTitleColor(.black, for: .normal)
            btn.setTitleColor(.white, for: .selected)
            
            btn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
            btn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        }
        
        OKBtn.setBackgroundImage(UIImage.init(color: .green), for: .selected)
        falseBtn.setBackgroundImage(UIImage.init(color: .red), for: .selected)
        
        stanbyOK.isHidden = true
        
        WBtn.isSelected = true
        oneBtn.isSelected = true
    }
    
    @IBAction func startTest(_ sender: Any) {
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "050A"  + tongdaoValue.decimalTo2Hexadecimal() + tiaoguangValue.decimalTo2Hexadecimal()
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    @IBAction func tongdaoClick(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        
        for btn in tongdaoBtnArray {
            btn.isSelected = false
        }
        sender.isSelected = true
        tongdaoValue = sender.tag
    }
    
    @IBAction func tiaoguang(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        
        for btn in tiaoguangBtnArray {
            btn.isSelected = false
        }
        sender.isSelected = true
        tiaoguangValue = sender.tag
    }
    
    @IBAction func chengpinResult(_ sender: UIButton) {
        
        if sender.isSelected {
            return
        }
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        sender.isSelected = true
        if sender.tag == 1 { //OK
            
            falseBtn.isSelected = false
            let string = "0501"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            OKBtn.isSelected = false
            let string = "0500"
            let parame = parameModel(dp: .factoryTestResule, value: string)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
    
    @IBAction func downLoadPic(_ sender: Any) {
        
        let parameTime = parameModel(dp: .cameraPic)
        KLMSmartNode.sharedInstacnce.readMessage(parameTime, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func stanbyClick(_ sender: Any) {
        
        SVProgressHUD.show()
        SVProgressHUD.setDefaultMaskType(.black)
        let string = "0509"
        let parame = parameModel(dp: .factoryTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMBaoZhuangTestViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .factoryTest, let value = message?.value as? String {
            
            if value.contains("050A") {
                SVProgressHUD.showSuccess(withStatus: "发送成功")
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
        
        //待机功耗
        if let value = message?.value as? String, message?.dp == .factoryTest {
            
            if value == "0509"{
                SVProgressHUD.dismiss()
                stanbyOK.isHidden = false
            }
        }
        
        //合格或者不合格
        if message?.dp == .factoryTestResule {

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

extension KLMBaoZhuangTestViewController: WKNavigationDelegate {
    
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
