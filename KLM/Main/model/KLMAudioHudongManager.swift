//
//  KLMAudioHudongManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/5.
//

import Foundation

class KLMAudioHudongManager: KLMAudioManager {
    
    private var random: Int = 1
    
    func startPlay() {
        
        playOrder = .audioFront
        
        if currentIndex == 0xFE {
            
            playHuanying()
            
        } else if currentIndex == 0xFF {
            
            playNocolor()
            
        } else {
            
            playFront()
        }
    }
    
    private func playHuanying() {
        
        let num = arc4random()%3 + 1
        let str = "hudongHuanying_\(num)"
        
        super.playWithPath(path: str)
    }
    
    private func playNocolor() {
        
        let num = arc4random()%5 + 1
        let str = "hudongNocolor_\(num)"
        
        super.playWithPath(path: str)
    }
    
    private func playIndex() {
        
        let str = "hudong_\(currentIndex)"
        
        super.playWithPath(path: str)
    }
    
    private func playFront() {
        
        let num = arc4random()%2 + 1
        random = Int(num)
        let str = "hudongColor_\(num)_前"
        
        super.playWithPath(path: str)
    }
    
    private func playBehind() {
        
        let str = "hudongColor_\(random)_后"
                
        super.playWithPath(path: str)
    }
    
    override func next() {
        
        if currentIndex == 0xFF || currentIndex == 0xFE {
            
            super.sendStop()
            return
        }
         
        switch playOrder {
        case .audioFront:
            playOrder = .audioIndex
            playIndex()
        case .audioIndex:
            playOrder = .audioBehind
            playBehind()
        case .audioBehind:
            super.sendStop()
        }
    }
    
    static let sharedHudong = KLMAudioHudongManager()
}

