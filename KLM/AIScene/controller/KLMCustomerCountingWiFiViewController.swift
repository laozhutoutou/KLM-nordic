//
//  KLMCustomerCountingWiFiViewController.swift
//  KLM
//
//  Created by 朱雨 on 2023/1/10.
//

import UIKit

class KLMCustomerCountingWiFiViewController: UIViewController, Editable {
    
    @IBOutlet weak var SSIDField: UITextField!
    @IBOutlet weak var passField: UITextField!
   
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var selectwifiBtn: UIButton!
    
    @IBOutlet weak var WifiNameLab: UILabel!
    @IBOutlet weak var passwordLab: UILabel!
    
    @IBOutlet weak var powerLab: UILabel!
    @IBOutlet weak var powerSwitch: UISwitch!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        let parame = parameModel(dp: .customerCounting)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("")
        contentView.isHidden = true
        ///显示空白页面
        showEmptyView()
        DispatchQueue.main.asyncAfter(deadline: 5) {
            self.hideEmptyView()
        }
        setupUI()
    }
    
    private func setupUI() {
        
        selectwifiBtn.backgroundColor = .lightGray.withAlphaComponent(0.1)
        selectwifiBtn.layer.cornerRadius = selectwifiBtn.height/2
        selectwifiBtn.setTitleColor(appMainThemeColor, for: .normal)
        doneBtn.layer.cornerRadius = doneBtn.height / 2
        doneBtn.backgroundColor = appMainThemeColor
        powerSwitch.onTintColor = appMainThemeColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        WifiNameLab.text = LANGLOC("Wi-Fi")
        SSIDField.placeholder = LANGLOC("Please enter the Wi-Fi")
        selectwifiBtn.setTitle(LANGLOC("Select Wi-Fi networks"), for: .normal)
        passwordLab.text = LANGLOC("Password")
        passField.placeholder = LANGLOC("Please enter the password")
        doneBtn.setTitle(LANGLOC("Done"), for: .normal)
        powerLab.text = LANGLOC("Customer Counting")
        
    }
    
    @IBAction func power(_ sender: UISwitch) {
        
        if sender.isOn {
            contentView.isHidden = false
        } else { //关闭
            
            SVProgressHUD.show()
            //发送关闭指令
            let parame = parameModel(dp: .customerCounting, value: "00")
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        }
    }
    
    private func sendWIfiMesssage() {
        
        KLMLog("发送WiFi信息给设备")
        SVProgressHUD.show(withStatus: LANGLOC("Send the WiFi information to the device"))
        
        let urlSSID: String = self.SSIDField.text!
        let urlPassword: String = self.passField.text!
        
        //打开
        let power: [UInt8] = [UInt8(1)]
        
        //32
        var urlSSIDBytes: [UInt8] = [UInt8](urlSSID.data(using: .utf8)!)
        urlSSIDBytes = urlSSIDBytes + [UInt8].init(repeating: 0, count: 32 - urlSSIDBytes.count)
        //32
        var urlPasswordBytes: [UInt8] = [UInt8](urlPassword.data(using: .utf8)!)
        urlPasswordBytes = urlPasswordBytes + [UInt8].init(repeating: 0, count: 32 - urlPasswordBytes.count)
        
        let parameters = Data.init(bytes: (power + urlSSIDBytes + urlPasswordBytes), count: (power + urlSSIDBytes + urlPasswordBytes).count)
        let allBytes: String = parameters.hex
        let parame = parameModel(dp: .customerCounting, value: allBytes)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func selectWifi(_ sender: Any) {
        
        KLMLocationManager.shared.getLocation {
            
            //弹框
            let vc = KLMWifiSelectViewController()
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            vc.wifiBlock = {[weak self] model in
                guard let self = self else { return  }
                self.SSIDField.text = model.WiFiName
                self.passField.text = model.WiFiPass
                
            }
            self.present(vc, animated: true)
        } failure: {
            
        }
    }
    
    @objc func appWillEnterForeground(){
        KLMLog("周期 ---将进入前台通知")
        //获取WiFi
        if let ssid = KLMLocationManager.getCurrentWifiName() {
            self.SSIDField.text = ssid
            if let wifilist = KLMWiFiManager.getWifiLists(), let model = wifilist.first(where: {$0.WiFiName == ssid}) {
                self.passField.text = model.WiFiPass
            }
        }
    }

    @IBAction func done(_ sender: Any) {
        
        if KLMTool.isEmptyString(string: SSIDField.text) == nil || KLMTool.isEmptyString(string: passField.text) == nil {
            
            return
        }
        
        sendWIfiMesssage()
    }
}

extension KLMCustomerCountingWiFiViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        if message?.dp == .customerCounting {
            hideEmptyView()
            if message?.opCode == .read, let power: Int = message?.value as? Int {
                powerSwitch.isOn = power == 1 ? true : false
                contentView.isHidden = power == 1 ? false : true
            } else {
                
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
