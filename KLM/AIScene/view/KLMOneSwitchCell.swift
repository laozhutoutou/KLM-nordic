//
//  KLMOneSwitchCell.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/15.
//

import UIKit

class KLMOneSwitchCell: KLMBaseTableViewCell {

    @IBOutlet weak var cameraSwitch: UISwitch!
    
    var cameraOnOff: Int!{
        
        didSet {
            self.cameraSwitch.isOn = cameraOnOff == 1 ? true : false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //添加手势
        let tap: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tap))
        tap.numberOfTapsRequired = 3
        addGestureRecognizer(tap)
    }
    
    @objc func tap() {
        
        KLMLog("连续点击")
        if cameraOnOff != 1 { //自动颜色开关没打开
            SVProgressHUD.showInfo(withStatus: LANGLOC("Please power on ") + LANGLOC("Devicecoloursensing"))
            return
        }
        let vc = KLMCMOSViewController()
        currentViewController()?.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func switchClick(_ sender: UISwitch) {
        
        if sender.isOn {
            
            let parame = parameModel(dp: .cameraPower, value: 1)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

        } else {//关
            
            let parame = parameModel(dp: .cameraPower, value: 2)
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: 1) {
            
            NotificationCenter.default.post(name: .refreshDeviceEdit, object: nil)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }
    
}

