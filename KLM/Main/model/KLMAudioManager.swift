//
//  KLMAudioManager.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/12.
//

import Foundation
import nRFMeshProvision

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
    
    func startPlay(index: Int, mode: Int) {

        switch mode {
        case AudioMode.AudioModeBiaozhun.rawValue: //标准
            KLMAudioBiaozhunManager.shared.startPlay(index: index, mode: .AudioModeBiaozhun)
        case AudioMode.AudioModeSexi.rawValue: //色系
            KLMAudioBiaozhunManager.shared.startPlay(index: index, mode: .AudioModeSexi)
        case 3: //互动
            KLMAudioHudongManager.shared.startPlay(index: index)
        case 4: //模特
            KLMAudioMoteManager.shared.startPlay(index: index)
        default:
            break
        }
    }
    
    func playWithPath(path: String) {
        
        
    }
    
    func stopPlay() {
        
        KLMAudioBiaozhunManager.shared.stopPlay()
        KLMAudioHudongManager.shared.stopPlay()
        KLMAudioMoteManager.shared.stopPlay()
    }
    
    func sendStop() {
        
        guard let currentNode = KLMAudioManager.shared.currentNode else { return  }
        let parameOn = parameModel.init(dp: .audio, value: 5)
        KLMSmartNode.sharedInstacnce.sendMessage(parameOn, toNode: currentNode)
    }
    
    deinit {
        
        stopPlay()
    }
    
    static let shared = KLMAudioManager()
    private override init(){}
}

