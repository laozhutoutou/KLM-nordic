//
//  KLMNavigationViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit

class KLMNavigationViewController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        
        self.interactivePopGestureRecognizer?.delegate = self
        
        let bar = UINavigationBar.appearance()
        bar.barTintColor = navigationBarColor
        bar.isTranslucent = false
        
        let barTitleDic = [NSAttributedString.Key.foregroundColor:UIColor.black,
                           NSAttributedString.Key.font:UIFont.systemFont(ofSize: 17)]
        bar.titleTextAttributes = barTitleDic
        
        //去掉导航栏横线
//        bar.setBackgroundImage(UIImage(), for: .default)
//        bar.shadowImage = UIImage()
        
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        //允许
        self.interactivePopGestureRecognizer?.isEnabled = true
        
        if viewControllers.count > 0 {
            viewController.hidesBottomBarWhenPushed = true
            
            viewController.navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(pushBack)) as? [UIBarButtonItem]
        }
        super.pushViewController(viewController, animated: animated)
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        
        // 解决iOS 14 popToRootViewController tabbar不自动显示问题
        if animated {
            let popController = viewControllers.last
            popController?.hidesBottomBarWhenPushed = false
        }
        return super.popToRootViewController(animated: animated)
    }
    
    @objc func pushBack() {
        
        popViewController(animated: true)
    }
}
