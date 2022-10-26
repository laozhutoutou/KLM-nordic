//
//  EmptyView.swift
//  KLM
//
//  Created by 朱雨 on 2021/10/16.
//

import Foundation
import UIKit

extension UIView {
    
    func setEmptyView() {
        
        var emptyView: UIView! = subviews.first(where: { $0.tag == 100 })
        if emptyView == nil {
            
            emptyView = UIView.init()
            emptyView.backgroundColor = .white
            emptyView.tag = 100
            emptyView.alpha = 0
            addSubview(emptyView)
            
            let indicatorView = UIActivityIndicatorView.init(style: .medium)
            indicatorView.tag = 101
            emptyView.addSubview(indicatorView)
            indicatorView.startAnimating()
            
            emptyView.snp.makeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
            
            indicatorView.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
        }
    }
    
    func showEmptyView() {
        
        setEmptyView()
        
        if let emptyView = subviews.first(where: { $0.tag == 100 }) {
            
            emptyView.alpha = 1.0
            if let indicatorView: UIActivityIndicatorView = emptyView.subviews.first(where: { $0.tag == 101 }) as? UIActivityIndicatorView{
               
                indicatorView.startAnimating()
            }
        }
    }
    
    func hideEmptyView() {
        
        if let emptyView = subviews.first(where: { $0.tag == 100 }) {
            emptyView.alpha = 0.0
            if let indicatorView: UIActivityIndicatorView = emptyView.subviews.first(where: { $0.tag == 101 }) as? UIActivityIndicatorView{
               
                indicatorView.stopAnimating()
            }
        }
    }
}

protocol Editable {
    
    func showEmptyView()
    func hideEmptyView()
}

extension Editable where Self: UIViewController {
    
    func showEmptyView() {
        
        view.showEmptyView()
    }
    
    func hideEmptyView() {
        
        view.hideEmptyView()
    }
}
