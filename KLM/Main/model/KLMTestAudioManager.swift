//
//  KLMTestAudioManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/12.
//

import Foundation
import AVFAudio
import nRFMeshProvision

//private enum AudioIndex {
//    case audioFront
//    case audioIndex
//    case audioBehind
//}

class KLMTestAudioManager: NSObject {
    
    private var audioPlayer: AVAudioPlayer?
    private var currentIndex: Int = 0
    private var playOrder: AudioIndex = .audioFront
    
    var currentNode: Node?
    
    func startPlay(type: Int) {
        
        if type > 16 {
            SVProgressHUD.showInfo(withStatus: "play index > 16")
            
            guard let currentNode = currentNode else { return  }
            let parameOn = parameModel.init(dp: .audio, value: 3)
            KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: currentNode)
            
            return
        }
        currentIndex = type
        playOrder = .audioFront
        KLMLog("index = \(type)")
        if type == 15 || type == 16 {
            
            playIndex()
            
        } else {
            
//            playFront()
            
            stopPlay()
            
            //设置类别
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            //启动音频会话管理,此时会阻断后台音乐的播放.
            try? AVAudioSession.sharedInstance().setActive(true)
            
            var str = "en_no_color"
            if Bundle.isChineseLanguage() {
                str = "ch_no_color"
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
    }
    
    private func playIndex() {
        
        stopPlay()
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let path = Bundle.main.path(forResource: "\(currentIndex)", ofType: "wav")
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
        
        let path = Bundle.main.path(forResource: "前", ofType: "wav")
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
        
        let path = Bundle.main.path(forResource: "后", ofType: "wav")
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
        
        guard let currentNode = currentNode else { return  }
        let parameOn = parameModel.init(dp: .audio, value: 3)
        KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: currentNode)
        
//        if currentIndex == 15 || currentIndex == 16 {
//
//            guard let currentNode = currentNode else { return  }
//            let parameOn = parameModel.init(dp: .audio, value: 3)
//            KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: currentNode)
//
//        } else {
//
//            switch playOrder {
//            case .audioFront:
//                playOrder = .audioIndex
//                playIndex()
//            case .audioIndex:
//                playOrder = .audioBehind
//                playBehind()
//            case .audioBehind:
//                guard let currentNode = currentNode else { return  }
//                let parameOn = parameModel.init(dp: .audio, value: 3)
//                KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: currentNode)
//            }
//        }
    }
    
    func stopPlay() {
        
        try? AVAudioSession.sharedInstance().setActive(false)
        audioPlayer?.stop()
        audioPlayer = nil
        
    }
    
    deinit {
        
        audioPlayer?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    static let shared = KLMTestAudioManager()
    private override init(){}
}

extension KLMTestAudioManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        stopPlay()
        KLMLog("结束播放")
        next()
    }
}

