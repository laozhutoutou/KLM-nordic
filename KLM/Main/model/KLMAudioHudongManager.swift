//
//  KLMAudioHudongManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/5.
//

import Foundation
import AVFAudio

class KLMAudioHudongManager: NSObject {
    
    private var audioPlayer: AVAudioPlayer?
    private var currentIndex: Int = 0
    private var playOrder: AudioIndex = .audioFront
    private var random: Int = 1
    
    func startPlay(index: Int) {
        
        currentIndex = index
        playOrder = .audioFront
        
        if index == 0xFF {
            
            playHuanying()
            
        } else if index == 0xFE {
            
            playNocolor()
            
        } else {
            
            playFront()
        }
    }
    
    private func playHuanying() {
        
        stopPlay()
        
        let num = arc4random()%3 + 1
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        var str = "hudongHuanying_\(num)"
        
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
    
    private func playNocolor() {
        
        stopPlay()
        
        let num = arc4random()%5 + 1
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        var str = "hudongNocolor_\(num)"
        
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
    
    private func playIndex() {
        
        stopPlay()
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        var str = "hudong_\(currentIndex)"
        
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
        
        let num = arc4random()%2 + 1
        random = Int(num)
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        var str = "hudongColor_\(num)_前"
        
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
        
        var str = "hudongColor_\(random)_后"
                
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
        
        if currentIndex == 0xFF || currentIndex == 0xFE {
            
            KLMAudioManager.shared.sendStop()
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
            KLMAudioManager.shared.sendStop()
        }
    }
        
    func stopPlay() {
        
        try? AVAudioSession.sharedInstance().setActive(false)
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    static let shared = KLMAudioHudongManager()
    private override init(){}
}

extension KLMAudioHudongManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        stopPlay()
        KLMLog("结束播放")
        next()
    }
}
