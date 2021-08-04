//
//  KLMTabBarController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit

class KLMTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTabBar()
        
        view.backgroundColor = UIColor.white
    }
    
    private func setUpTabBar() {
        
        tabBar.isTranslucent = false
        
        if #available(iOS 13.0, *) {
            
            tabBar.unselectedItemTintColor = UIColor.white
        }
        
        setupAllChildViewController()
    }
    
    private func setupAllChildViewController() {
        
        let scene = KLMUnNameListViewController()
        let group = KLMGroupViewController()
        let setting = KLMSettingViewController()
        
        setupOneViewController(scene, LANGLOC("AiScene"), "icon_device_unselect", "icon_device_select")
        setupOneViewController(group, LANGLOC("Group"), "icon_group_unselect", "icon_group_select")
        setupOneViewController(setting, LANGLOC("More"), "icon_more_unselect", "icon_more_select")
    }
    
    private func setupOneViewController(_ vc : UIViewController, _ title : String, _ imageName : String, _ selectImageName : String) {
        
        vc.tabBarItem.title = title
        vc.tabBarItem.image = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal)
        vc.tabBarItem.selectedImage = UIImage(named: selectImageName)?.withRenderingMode(.alwaysOriginal)
        let dicNormal = [NSAttributedString.Key.foregroundColor  :  UIColor.orange, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11)]
        vc.tabBarItem.setTitleTextAttributes(dicNormal, for: .normal)
        
        //选中
        let dicSelect = [NSAttributedString.Key.foregroundColor  :  UIColor.black, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 11)]
        vc.tabBarItem.setTitleTextAttributes(dicSelect, for: .normal)
        
        //移动title offset
        vc.tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 0)
        
        let nav = KLMNavigationViewController(rootViewController: vc)
        addChild(nav)
    }
}
