//
//  KLMAudioManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/12.
//

import Foundation
import nRFMeshProvision
import AVFAudio

enum AudioIndex {
    case audioFront
    case audioIndex
    case audioBehind
}

enum AudioMode: Int {
    case AudioModeBiaozhun = 1
    case AudioModeSexi
    case AudioModeHudong
    case AudioModeMote
}

class KLMAudioManager: NSObject {
    
    var currentNode: Node?
    private var audioPlayer: AVAudioPlayer?
    var currentIndex: Int = 0
    var playOrder: AudioIndex = .audioFront
    var currentMode: AudioMode = .AudioModeBiaozhun
        
    func startPlay(index: Int, mode: Int) {
        
        currentIndex = index
        currentMode = AudioMode.init(rawValue: mode)!
        
        switch currentMode {
        case .AudioModeBiaozhun, //标准
                .AudioModeSexi: //色系

            KLMAudioBiaozhunManager.sharedBiaozhun.currentMode = currentMode
            KLMAudioBiaozhunManager.sharedBiaozhun.currentIndex = currentIndex
            KLMAudioBiaozhunManager.sharedBiaozhun.startPlay()
            
        case .AudioModeHudong: //互动
            KLMAudioHudongManager.sharedHudong.currentIndex = currentIndex
            KLMAudioHudongManager.sharedHudong.startPlay()
        case .AudioModeMote: //模特
            KLMAudioHudongManager.sharedHudong.currentIndex = currentIndex
            KLMAudioMoteManager.sharedMote.startPlay()

        }
    }
    
    func playWithPath(path: String) {
        
        stopPlay()
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let path = Bundle.main.path(forResource: path, ofType: "wav")
        guard let path = path else { return }
        if audioPlayer == nil {
            audioPlayer = try! AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: path))
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 1
        }
        audioPlayer?.play()
    }
    
    func stopPlay() {
        
        try? AVAudioSession.sharedInstance().setActive(false)
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func sendStop() {
        
        guard let currentNode = KLMAudioManager.shared.currentNode else { return  }
        let parameOn = parameModel.init(dp: .audio, value: 5)
        KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: currentNode)
    }
    
    func next() {

        
    }
    
    static let shared = KLMAudioManager()

//    private override init(){}
}

extension KLMAudioManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        stopPlay()
        KLMLog("结束播放")
        next()
    }
}

