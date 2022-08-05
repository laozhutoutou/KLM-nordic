//
//  KLMTestImageCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/1.
//

import UIKit
import Kingfisher
import WebKit

class KLMTestImageCell: UICollectionViewCell {

    var webView: WKWebView?
    
    var url: String? {
        didSet {
            let url = URL.init(string: url!)
            if webView == nil {
                webView = WKWebView.init()
                webView?.frame = self.bounds
                self.addSubview(webView!)
                webView?.navigationDelegate = self
            }
            webView?.showEmptyView()
            let request = URLRequest(url: url!)
            webView?.load(request)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
}

extension KLMTestImageCell: WKNavigationDelegate {
    
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
