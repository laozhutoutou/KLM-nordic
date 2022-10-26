//
//  KLMTestVersion1ViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/10/25.
//

import UIKit

class KLMTestVersion1ViewController: UIViewController {
    
    @IBOutlet weak var currentgonglvLab: UILabel!
    @IBOutlet weak var gonglvView: UIView!
    @IBOutlet weak var gonglvLab: UILabel!
    
    @IBOutlet weak var currentqudongLab: UILabel!
    @IBOutlet weak var qudongView: UIView!
    @IBOutlet weak var qudongLab: UILabel!
    
    var gonglv: Int = 1 {
        didSet {
            gonglvLab.text = gonglvList[gonglv - 1]
        }
    }
    var qudong: Int = 1 {
        didSet {
            qudongLab.text = qudongLIst[qudong - 1]
        }
    }
    let gonglvList: [String] = ["35W有摄像头","25W有摄像头","35W无摄像头"]
    let qudongLIst: [String] = ["diodes","ocx"]
    
    var isFirst: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "硬件信息"
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        SVProgressHUD.show()
        //读取数据
        let parame = parameModel(dp: .hardwareInfo)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    ///功率
    @IBAction func tapGonglv(_ sender: Any) {
        
        let menuViewrect: CGRect = gonglvView.convert(gonglvView.bounds, to: KLMKeyWindow)
        let point: CGPoint = CGPoint.init(x: menuViewrect.origin.x, y: menuViewrect.origin.y + menuViewrect.size.height)
        YBPopupMenu.show(at: point, titles: gonglvList, icons: nil, menuWidth: 150) { popupMenu in
            popupMenu?.priorityDirection = .none
            popupMenu?.arrowHeight = 0
            popupMenu?.minSpace = menuViewrect.origin.x
            popupMenu?.dismissOnSelected = true
            popupMenu?.isShadowShowing = false
            popupMenu?.delegate = self
            popupMenu?.cornerRadius = 0
            popupMenu?.tag = 100
            
        }
    }
    
    ///驱动
    @IBAction func tapQudong(_ sender: Any) {
        
        let menuViewrect: CGRect = qudongView.convert(qudongView.bounds, to: KLMKeyWindow)
        let point: CGPoint = CGPoint.init(x: menuViewrect.origin.x, y: menuViewrect.origin.y + menuViewrect.size.height)
        YBPopupMenu.show(at: point, titles: qudongLIst, icons: nil, menuWidth: 150) { popupMenu in
            popupMenu?.priorityDirection = .none
            popupMenu?.arrowHeight = 0
            popupMenu?.minSpace = menuViewrect.origin.x
            popupMenu?.dismissOnSelected = true
            popupMenu?.isShadowShowing = false
            popupMenu?.delegate = self
            popupMenu?.cornerRadius = 0
            
        }
    }
    
    @IBAction func confirmClick(_ sender: Any) {
        
        isFirst = false
        SVProgressHUD.show()
        
        let gonglvv = gonglv.decimalTo2Hexadecimal()
        let qudongg = qudong .decimalTo2Hexadecimal()
        let parame = parameModel(dp: .hardwareInfo, value: gonglvv + qudongg)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
}

extension KLMTestVersion1ViewController: YBPopupMenuDelegate {
    
    func ybPopupMenu(_ ybPopupMenu: YBPopupMenu!, didSelectedAt index: Int) {
        
        if ybPopupMenu.tag == 100 { ///功率
            gonglv = index + 1
            
        } else { ///驱动
            qudong = index + 1

        }
    }
}

extension KLMTestVersion1ViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if let value = message?.value as? [UInt8], value.count >= 2 , message?.dp == .hardwareInfo {
            
            if isFirst {
                let gonglv = Int(value[0])
                let qudong = Int(value[1])
                if gonglv > 0 && qudong > 0 && gonglv <= gonglvList.count && qudong <= qudongLIst.count {
                    self.gonglv = gonglv
                    self.qudong = qudong
                    currentgonglvLab.text = gonglvList[gonglv - 1]
                    currentqudongLab.text = qudongLIst[qudong - 1]
                }
            } else {
                SVProgressHUD.showInfo(withStatus: "成功")
                DispatchQueue.main.asyncAfter(deadline: 1) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

