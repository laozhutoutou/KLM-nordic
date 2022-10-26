//
//  KLMTestBiaodingViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/9/27.
//

import UIKit

private enum Status: Int {
    case none = 1
    case isBiaoding = 2
    case isVerify = 3
}

class KLMTestBiaodingViewController: UIViewController {

    @IBOutlet weak var indexLab: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    
    @IBOutlet weak var verifyView: UIView!
    @IBOutlet weak var verifyBtn: UIButton!
    @IBOutlet weak var verifyLab: UILabel!
    
    private var statu: Status = .none {
        didSet {
            switch statu {
            case .none:
                verifyView.isHidden = true
            case .isBiaoding:
                verifyView.isHidden = false
                indexLab.text = "已标定，但验证未完成，可再次标定"
                startBtn.setTitle("重新标定", for: .normal)
            case .isVerify:
                indexLab.text = "已完成验证"
                verifyView.isHidden = false
                verifyLab.text = "验证成功"
                verifyLab.textColor = .green
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        setupData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "白平衡标定"
        
        statu = .none
    }
    
    private func setupData() {
        
        SVProgressHUD.show(withStatus: "查询状态")
        let parame = parameModel(dp: .biaoding)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }

    @IBAction func start(_ sender: Any) {
        
//        if statu == .isVerify {
//            SVProgressHUD.showInfo(withStatus: "设备已经完成验证.")
//            return
//        }
        
        SVProgressHUD.show()
        let parame = parameModel(dp: .biaoding, value: "01")
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    ///验证
    @IBAction func verify(_ sender: Any) {
        
//        if statu == .isVerify {
//            SVProgressHUD.showInfo(withStatus: "设备已经完成验证.")
//            return
//        }
        
//        verifyLab.text = nil
        SVProgressHUD.show()
        let parame = parameModel(dp: .biaoding, value: "02")
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        
        DispatchQueue.main.asyncAfter(deadline: 3) {
            let vc = KLMTestViewPostionViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func checkStatus() {
        
        DispatchQueue.main.asyncAfter(deadline: 5) {
            
            self.setupData()
            
        }
    }

}

extension KLMTestBiaodingViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .biaoding, let value = message?.value as? [UInt8] {
            SVProgressHUD.dismiss()
            if message?.opCode == .read {///read和蓝牙主动下发消息
                
                if value.count >= 2 {
                    let first: Int = Int(value[0])
                    let second: Int = Int(value[1])
                    if first == 0 { ///标定进度
                        
                        if second == 0xff { ///标定完成
                            SVProgressHUD.show(withStatus: "查询状态")
                            checkStatus()
                            return
                        }
                        let progress = Float(second) / 100.0
                        SVProgressHUD.showProgress(progress, status: "\(second)%")
                        
                    } else { ///验证结果
                        
                        if second == 1 { //成功
                            statu = .isVerify
                            verifyLab.text = "验证成功"
                            
                        } else { //失败
                            
                            verifyLab.text = "验证失败"
                            verifyLab.textColor = .red
                        }
                    }
                } else { ///APP主动去读取状态
                    
                    statu = Status(rawValue: Int(value[0]))!
                }
                
            } else { ///send
                let vv = value[0]
                if vv == 1 {
                    SVProgressHUD.show(withStatus: "请等待设备标定")
                } else {
//                    SVProgressHUD.show(withStatus: "请等待设备验证")
                    SVProgressHUD.showInfo(withStatus: "验证开始")
                    
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
