//
//  KLMNavigationViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit

class KLMNavigationViewController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    private var pushing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        self.interactivePopGestureRecognizer?.delegate = self
        
        let bar = UINavigationBar.appearance()
        
        if #available(iOS 15.0, *) {///适配iOS15
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.backgroundColor = navigationBarColor
            navBarAppearance.shadowColor = UIColor.clear
            bar.standardAppearance = navBarAppearance
            bar.scrollEdgeAppearance = navBarAppearance
        } else {
            
            bar.barTintColor = navigationBarColor
            //去掉导航栏横线
            bar.setBackgroundImage(UIImage(), for: .default)
            bar.shadowImage = UIImage()
            
        }
        //不透明
        bar.isTranslucent = false
        
        let barTitleDic = [NSAttributedString.Key.foregroundColor:UIColor.black,
                           NSAttributedString.Key.font:UIFont.systemFont(ofSize: 17)]
        bar.titleTextAttributes = barTitleDic
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        if pushing {
            KLMLog("被拦截了")
            return
        } else {
            pushing = true
        }
        
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
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        pushing = false
    }
    
    @objc func pushBack() {
        
        popViewController(animated: true)
    }
}
