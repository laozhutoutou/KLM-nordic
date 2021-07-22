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
