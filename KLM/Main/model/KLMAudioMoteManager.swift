//
//  KLMAudioMoteManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/11/5.
//

import Foundation
import AVFAudio

class KLMAudioMoteManager: NSObject {
    
    private var audioPlayer: AVAudioPlayer?
    private var currentIndex: Int = 0
    
    func startPlay(index: Int) {
        
        currentIndex = index
        
        playIndex()
    }
    
    private func playIndex() {
        
        stopPlay()
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        var str = "mote_\(currentIndex)"
        
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
        
        KLMAudioManager.shared.sendStop()
    }
        
    func stopPlay() {
        
        try? AVAudioSession.sharedInstance().setActive(false)
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    static let shared = KLMAudioMoteManager()
    private override init(){}
}

extension KLMAudioMoteManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        stopPlay()
        KLMLog("结束播放")
        next()
    }
}
