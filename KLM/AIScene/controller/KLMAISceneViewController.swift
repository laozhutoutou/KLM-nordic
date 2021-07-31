//
//  KLMAISceneViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/2.
//

import UIKit

class KLMAISceneViewController: UIViewController {
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: KLMScreenW, height: KLMScreenH - KLM_TopHeight - KLM_TabbarHeight))
        scrollView.isPagingEnabled = true
        scrollView.contentSize = CGSize(width: KLMScreenW * 2, height: 0)
        scrollView.isScrollEnabled = false
        return scrollView
    }()
    
    lazy var unNameBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 55, height: 18))
        btn.setTitle(LANGLOC("unName"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.lightGray, for: .normal)
        btn.addTarget(self, action: #selector(unNameClick), for: .touchUpInside)
        btn.setTitleColor(UIColor.black, for: .selected)
        btn.contentHorizontalAlignment = .left
        
        return btn
    }()
    
    lazy var reNameBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 55, height: 18))
        btn.setTitle(LANGLOC("ReName"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.lightGray, for: .normal)
        btn.addTarget(self, action: #selector(reNameClick), for: .touchUpInside)
        btn.setTitleColor(UIColor.black, for: .selected)
        btn.contentHorizontalAlignment = .left
        
        return btn
    }()
    
    lazy var addBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 10, height: 18))
        btn.setTitle("+", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.lightGray, for: .normal)
        btn.addTarget(self, action: #selector(addDevice), for: .touchUpInside)
        btn.contentHorizontalAlignment = .right
        btn.backgroundColor = .blue
        return btn
    }()
    
    lazy var searchBtn: UIButton = {
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 18))
        btn.setTitle("search", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(UIColor.lightGray, for: .normal)
        btn.addTarget(self, action: #selector(search), for: .touchUpInside)
        btn.contentHorizontalAlignment = .right
        btn.backgroundColor = .red
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(self.scrollView)
        
        setupChildViewController()
        
        self.unNameBtn.isSelected = true
        self.unNameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        DispatchQueue.main.asyncAfter(deadline: 0.5, execute: {
        
            self.showVc(index: 0)
        })
        
        let nuNameItem = UIBarButtonItem.init(customView: self.unNameBtn)
        let reNameItem = UIBarButtonItem.init(customView: self.reNameBtn)
        navigationItem.leftBarButtonItems = [nuNameItem,reNameItem]
        
        let addItem = UIBarButtonItem.init(customView: self.addBtn)
        let searchItem = UIBarButtonItem.init(customView: self.searchBtn)
        navigationItem.rightBarButtonItems = [addItem,searchItem]
        
    }
    
    
    @objc func addDevice() {
        
        let vc = KLMAddDeviceViewController()
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @objc func search() {
        
        let vc = KLMSearchViewController()
        let nav = KLMNavigationViewController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        present(nav, animated: true, completion: nil)
        
    }
    
    func setupChildViewController() {
        
        let unName = KLMUnNameListViewController()
        addChild(unName)
        
        let reName = KLMReNameListViewController()
        addChild(reName)
        
    }
    
    func showVc(index: Int){
        
        let offsetX = CGFloat(index) * KLMScreenW
        let vc = self.children[index]
        
        if vc.isViewLoaded {
            return
        }
        
        vc.view.frame = CGRect(x: offsetX, y: 0, width: KLMScreenW, height: scrollView.height)
        self.scrollView.addSubview(vc.view)
    }
    
    @objc func unNameClick() {
        
        self.unNameBtn.isSelected = true
        self.reNameBtn.isSelected = false
        self.unNameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        self.reNameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        let offsetX = 0
        self.scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        self.showVc(index: 0)
    }
    
    @objc func reNameClick() {
        
        self.unNameBtn.isSelected = false
        self.reNameBtn.isSelected = true
        self.unNameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        self.reNameBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        
        
        let offsetX = KLMScreenW
        self.scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        self.showVc(index: 1)
    }
    
}


