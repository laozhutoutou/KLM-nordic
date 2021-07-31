//
//  KLMText1ViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/28.
//

import UIKit

class KLMText1ViewController: UIViewController {

    @IBOutlet weak var auToSwitch: UISwitch!
    @IBOutlet weak var intervalLab: UILabel!
    
    @IBOutlet weak var waitLab: UILabel!
    @IBOutlet weak var intervalSlider: UISlider!
    @IBOutlet weak var waitSlider: UISlider!
    
    @IBOutlet weak var startBtn: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
        intervalSlider.value = 30
        waitSlider.value = 3
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.startBtn.isEnabled = false
        
    }
    
    @IBAction func intervalValueChanged(_ sender: UISlider) {
        intervalLab.text = "\(Int(intervalSlider.value))s"
        
    }
    
    @IBAction func waitValueChanged(_ sender: UISlider) {
        
        waitLab.text = "\(Int(waitSlider.value))s"
    }
    //间隔
    @IBAction func interval(_ sender: UISlider) {
        
        sendAutoData()
    }
    
    //等待
    @IBAction func wait(_ sender: UISlider) {
        
        sendAutoData()
    }
    
    @IBAction func start(_ sender: UIButton) {
        
        let string = "02000001"
        let parame = parameModel(dp: .colorTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
    @IBAction func touch(_ sender: UISwitch) {
        
        if sender.isOn {
            intervalSlider.isEnabled = true
            waitSlider.isEnabled = true
            self.startBtn.isEnabled = false
        } else {
            
            intervalSlider.isEnabled = false
            waitSlider.isEnabled = false
            self.startBtn.isEnabled = true
        }
    }
    
    func sendAutoData() {
        
        let interval = Int(intervalSlider.value).decimalTo2Hexadecimal()
        
        let wait = Int(waitSlider.value).decimalTo2Hexadecimal()
        let string = "01" + interval + wait + "00"
        let parame = parameModel(dp: .colorTest, value: string)
        KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
    }
    
}

extension KLMText1ViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        KLMLog("success")
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}

