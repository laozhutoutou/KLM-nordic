//
//  KLMAudioViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/11.
//

import UIKit

class KLMAudioViewController: UIViewController {
    
    @IBOutlet weak var modeView: UIView!
    @IBOutlet weak var modeLab: UILabel!
    @IBOutlet weak var spectrumImageView: UIImageView!
    
    let modeList = ["不播报", "标准模式", "色系模式", "互动模式", "模特模式"]
    var currentMode: Int = 0 {
        didSet {
            modeLab.text = modeList[currentMode]
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        KLMAudioManager.shared.currentNode = KLMHomeManager.currentNode
        
        navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(dimiss)) as? [UIBarButtonItem]
    }
    
    @objc func dimiss() {
        ///发送语音关闭指令
        KLMAudioManager.shared.stopPlay()
        
        ///关闭语音播报
        let parame = parameModel.init(dp: .audio, value: 0)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
        dismiss(animated: true)
    }
    
    private func setupData() {
        
        let parame = parameModel(dp: .audio)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func tapCategory(_ sender: UITapGestureRecognizer) {
        
        let menuViewrect: CGRect = modeView.convert(modeView.bounds, to: KLMKeyWindow)
        let point: CGPoint = CGPoint.init(x: menuViewrect.origin.x, y: menuViewrect.origin.y + menuViewrect.size.height)
        YBPopupMenu.show(at: point, titles: modeList, icons: nil, menuWidth: 150) { popupMenu in
            popupMenu?.priorityDirection = .none
            popupMenu?.arrowHeight = 0
            popupMenu?.minSpace = menuViewrect.origin.x
            popupMenu?.isShadowShowing = false
            popupMenu?.delegate = self
            popupMenu?.cornerRadius = 0
        }
    }
}

extension KLMAudioViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .audio, let value = message?.value as? [UInt8] {
            if message?.opCode == .read {
                
                if value.count >= 3 { ///设备端主动下发语音指令
                    
                    let mode = Int(value[0])
                    let index = Int(value[1])
                    let spectrum = Int(value[2])
                    if mode > 0 && mode < 5 {
                        KLMAudioManager.shared.startPlay(index: index, mode: mode)
                    }
                    if spectrum > 0 && spectrum < 40 {
                        let name = "spectrum_\(spectrum)"
                        spectrumImageView.image = UIImage.init(named: name)
                    } else {
                        spectrumImageView.image = UIImage.init()
                    }
                    
                } else { //获取到开关状态
                    
                    let firstIndex = Int(value[0])
                    currentMode = firstIndex
                }
            }
        }
    }
        
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

extension KLMAudioViewController: YBPopupMenuDelegate {
    
    func ybPopupMenu(_ ybPopupMenu: YBPopupMenu!, didSelectedAt index: Int) {
        
        currentMode = index
        
        let parame = parameModel.init(dp: .audio, value: index)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}
