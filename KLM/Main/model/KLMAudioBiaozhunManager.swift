//
//  KLMAudioBiaozhunManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/5.
//

import Foundation
import AVFAudio

class KLMAudioBiaozhunManager: NSObject {
    
    private var audioPlayer: AVAudioPlayer?
    private var currentIndex: Int = 0
    private var playOrder: AudioIndex = .audioFront
    private var currentMode: AudioMode = .AudioModeBiaozhun
    
    func startPlay(index: Int, mode: AudioMode) {
        
        currentIndex = index
        playOrder = .audioFront
        currentMode = mode
        
        if currentMode == .AudioModeBiaozhun {
            
            if index > 16 {
                SVProgressHUD.showInfo(withStatus: "play index > 16")
                
                KLMAudioManager.shared.sendStop()
                
                return
            }
            
            if index == 15 || index == 16 {
                
                playIndex()
                
            } else {
                
                playFront()
            }
            
        } else { //色系
            
            if index > 13 {
                SVProgressHUD.showInfo(withStatus: "play index > 10")
                
                KLMAudioManager.shared.sendStop()
                
                return
            }
            
            playFront()
        }
    }
    
    private func playIndex() {
        
        stopPlay()
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        var str = ""
        if currentMode == .AudioModeBiaozhun {
            str = "\(currentIndex)_en"
            if Bundle.isChineseLanguage() {
                str = "\(currentIndex)"
            }
        } else {
            str = "sexi_\(currentIndex)"
        }
        
        let path = Bundle.main.path(forResource: str, ofType: "wav")
        guard let path = path else { return }
        if audioPlayer == nil {
            audioPlayer = try! AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: path))
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 1
        }
        audioPlayer?.play()
    }
    
    private func playFront() {
        
        stopPlay()
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        var str = ""
        if currentMode == .AudioModeBiaozhun {
            str = "前_en"
            if Bundle.isChineseLanguage() {
                str = "前"
            }
        } else {
            str = "sexi_前"
        }
        
        let path = Bundle.main.path(forResource: str, ofType: "wav")
        guard let path = path else { return }
        if audioPlayer == nil {
            audioPlayer = try! AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: path))
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 1
        }
        audioPlayer?.play()
    }
    
    private func playBehind() {
        
        stopPlay()
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        var str = ""
        if currentMode == .AudioModeBiaozhun {
            str = "后_en"
            if Bundle.isChineseLanguage() {
                str = "后"
            }
        } else {
            str = "sexi_后"
        }
                
        let path = Bundle.main.path(forResource: str, ofType: "wav")
        guard let path = path else { return }
        if audioPlayer == nil {
            audioPlayer = try! AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: path))
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 1
        }
        audioPlayer?.play()
    }
    
    private func next() {
        
        if currentMode == .AudioModeBiaozhun {
            
            if currentIndex == 15 || currentIndex == 16 {
                
                KLMAudioManager.shared.sendStop()
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
            KLMAudioManager.shared.sendStop()
        }
    }
        
    func stopPlay() {
        
        try? AVAudioSession.sharedInstance().setActive(false)
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    static let shared = KLMAudioBiaozhunManager()
    private override init(){}
}

extension KLMAudioBiaozhunManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        stopPlay()
        KLMLog("结束播放")
        next()
    }
}
