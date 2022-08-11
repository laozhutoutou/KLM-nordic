//
//  KLMAudioViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/11.
//

import UIKit
import AVFAudio

class KLMAudioViewController: UIViewController {
    
    var audioPlayer: AVAudioPlayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //设置类别
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        //启动音频会话管理,此时会阻断后台音乐的播放.
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    deinit {
        
        audioPlayer?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    @IBAction func audioSwitch(_ sender: UISwitch) {
        
        if sender.isOn {
            
            stopPlay()
            
            let path = Bundle.main.path(forResource: "2", ofType: "wav")
            if audioPlayer == nil {
                audioPlayer = try! AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: path!))
                audioPlayer?.delegate = self
                audioPlayer?.prepareToPlay()
                audioPlayer?.volume = 1
            }
            audioPlayer?.play()
        }
    }
    
    private func stopPlay() {
        
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

extension KLMAudioViewController: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        stopPlay()
        KLMLog("结束播放")
    }
}
