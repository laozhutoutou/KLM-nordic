//
//  KLMRefreshHeader.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/24.
//

import UIKit

class KLMRefreshHeader: MJRefreshNormalHeader {

    override func prepare() {
        super.prepare()
        
        self.lastUpdatedTimeLabel?.isHidden = true
        self.stateLabel?.isHidden = true
    }

}

class KLMLogManager: NSObject {
    
    func logDateTime() -> String {
        self.dateFormatter.string(from: Date.init())
    }
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss.SSS"
        return dateFormatter
    }()
    
    //单例
    static let sharedInstacnce = KLMLogManager()
    private override init(){}
}
