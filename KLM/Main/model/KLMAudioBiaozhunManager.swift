//
//  KLMAudioBiaozhunManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/5.
//

import Foundation

class KLMAudioBiaozhunManager: KLMAudioManager {
    
    func startPlay() {
        
        playOrder = .audioFront
        
        if currentMode == .AudioModeBiaozhun {
            
            if currentIndex > 16 {
                SVProgressHUD.showInfo(withStatus: "play index > 16")
                
                super.sendStop()
                
                return
            }
            
            if currentIndex == 15 || currentIndex == 16 {
                
                playIndex()
                
            } else {
                
                playFront()
            }
            
        } else { //色系
            
            if currentIndex > 13 {
                SVProgressHUD.showInfo(withStatus: "play index > 13")
                
                super.sendStop()
                
                return
            }
            
            playFront()
        }
    }
    
    private func playIndex() {
                
        var str = ""
        if currentMode == .AudioModeBiaozhun {
            str = "\(currentIndex)_en"
            if Bundle.isChineseLanguage() {
                str = "\(currentIndex)"
            }
        } else {
            str = "sexi_\(currentIndex)"
        }
        
        super.playWithPath(path: str)
    }
    
    private func playFront() {
        
        var str = ""
        if currentMode == .AudioModeBiaozhun {
            str = "前_en"
            if Bundle.isChineseLanguage() {
                str = "前"
            }
        } else {
            str = "sexi_前"
        }
        
        super.playWithPath(path: str)
    }
    
    private func playBehind() {
            
        var str = ""
        if currentMode == .AudioModeBiaozhun {
            str = "后_en"
            if Bundle.isChineseLanguage() {
                str = "后"
            }
        } else {
            str = "sexi_后"
        }
                
        super.playWithPath(path: str)
    }
    
    override func next() {
        
        if currentMode == .AudioModeBiaozhun {
            
            if currentIndex == 15 || currentIndex == 16 {
                
                super.sendStop()
                return
            }
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
    
    static let sharedBiaozhun = KLMAudioBiaozhunManager()
}
