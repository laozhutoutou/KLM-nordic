//
//  KLMCheckImagesViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/1.
//

import UIKit
import nRFMeshProvision

class KLMCheckImagesViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var nodes: [Node] = [Node]()
    var timer: Timer?
    private var currentTime: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
          
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = appBackGroupColor
        self.collectionView.register(UINib(nibName: String(describing: KLMTestImageCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: KLMTestImageCell.self))
        
        SVProgressHUD.show()
        SVProgressHUD.dismiss(withDelay: 5)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(forTimer), userInfo: nil, repeats: true)
    }
    
    @objc private func forTimer() {
        
        let node = nodes[currentTime]
        sendMsg(node: node)
        
        currentTime += 1
        KLMLog("定时时间 = \(currentTime)")
        if currentTime >= nodes.count {
            stopTimer()
        }
    }
    
    private func stopTimer() {
        KLMLog("停止计时")
        currentTime = 0
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func sendMsg(node: Node) {
        
        let parame = parameModel(dp: .cameraPic)
        let model = KLMHomeManager.getModelFromNode(node: node)!
        let dpString = parame.dp!.rawValue.decimalTo2Hexadecimal()
        if let opCode = UInt8("1C", radix: 16) {
            let parameters = Data(hex: dpString)
            KLMLog("readParameter = \(parameters.hex)")
            let message = RuntimeVendorMessage(opCode: opCode, for: model, parameters: parameters)
            do {
                
                try MeshNetworkManager.instance.send(message, to: model)
            } catch  {
                
                print(error)
            }
        }
    }
}

extension KLMCheckImagesViewController: UICollectionViewDelegate, UICollectionViewDataSource,  UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.nodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let itemWidth: CGFloat = (KLMScreenW - 16*2 - 15) / 2
        let itemHeight: CGFloat = 174.0
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 15
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: KLMTestImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: KLMTestImageCell.self), for: indexPath) as! KLMTestImageCell
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

extension KLMCheckImagesViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        
        ///过滤消息，不是当前手机发出的消息不处理（这个可以不加，因为不是当前手机的信息nordic底层已经处理）
        if manager.meshNetwork?.localProvisioner?.node?.unicastAddress != destination {
            KLMLog("别的手机发的消息")
            return
        }
        
        switch message {
        case let message as UnknownMessage://收发消息
            if let parameters = message.parameters {
                //如果是开关 "0101"
                KLMLog("messageResponse = \(parameters.hex)")
                
                if parameters.count >= 3 {
                    
                    var response = parameModel()
                        
                    ///有error
                    let status = parameters[0]
                    let dpData = parameters[1]
                    let value: Data = parameters.suffix(from: 2)
                    
                    let dp = DPType(rawValue: Int(dpData))
                    if status != 0 { ///返回错误

                        var err = MessageError()
                        err.code = Int(status)
                        err.dp = dp
                        err.message = LANGLOC("Dataexception")
                        if status == 2 {
                            err.message = LANGLOC("turnOnLightTip")
                        }
                        if dp == .cameraPic && status == 1 {
                            err.message = LANGLOC("The light failed to connect to WiFi. Maybe the WiFi password is incorrect")
                        }
                        KLMShowError(err)
                        return
                    }
                    response.dp = dp
                    
                    switch response.dp {
                    case .cameraPic:
                        response.value = [UInt8](value)
                        if let data = response.value as? [UInt8], data.count >= 4 {
                            let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp"
                            KLMLog("ip = \(ip)")
                            if let index = nodes.firstIndex(where: {$0.unicastAddress == source}) {
                                let indexPath = IndexPath.init(item: index, section: 0)
                                if let cell: KLMTestImageCell = collectionView.cellForItem(at: indexPath) as? KLMTestImageCell {
                                    
                                    cell.url = ip
                                }
                                
                            }
                        }
 
                    default:
                        break
                    }
                }
            }
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        
        KLMLog("消息发送成功")
        
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        
        KLMLog("升级发送消息失败 - \(error.localizedDescription)")

    }
}
