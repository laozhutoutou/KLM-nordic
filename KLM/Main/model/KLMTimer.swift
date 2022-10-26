//
//  KLMTimer.swift
//  KLM
//
//  Created by 朱雨 on 2022/4/29.
//

import Foundation

protocol KLMTimerDelegate: AnyObject {
    
    func timeDidTimeout(_ timer: KLMTimer)
}

class KLMTimer {

    private var timer: Timer?
    private var timeout: Int!
    ///当前秒
    private var currentTime: Int = 0
    /// 标识
    var tag: Int = 0
    weak var delegate: KLMTimerDelegate?
    
    func startTimer(timeOut: Int? = 10) {
        KLMLog("开始计时，超时时间 = \(timeOut!)")
        timeout = timeOut
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(forTimer), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        KLMLog("停止计时")
        currentTime = 0
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
    
    @objc private func forTimer() {
        
        currentTime += 1
        KLMLog("定时时间 = \(currentTime)")
        if currentTime > timeout {//超时
            KLMLog("时间超时了。。。")
            stopTimer()
            self.delegate?.timeDidTimeout(self)
        }
    }
    
    private func timeIsValid() -> Bool {
        if let time = timer, time.isValid == true {
            return true
        }
        return false
    }
    
    deinit {
        KLMLog("定时器销毁")
        stopTimer()
    }
}
