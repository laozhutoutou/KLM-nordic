//
//  KLMAudioMoteManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/5.
//

import Foundation

class KLMAudioMoteManager: KLMAudioManager {
    
    func startPlay() {
                
        playIndex()
    }
    
    private func playIndex() {
                
        let str = "mote_\(currentIndex)"
        
        super.playWithPath(path: str)
    }
    
    override func next() {
        
        super.sendStop()
    }
    
    static let sharedMote = KLMAudioMoteManager()
}

