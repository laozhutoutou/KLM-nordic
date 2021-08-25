//
//  KLMUpdateManager.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/25.
//

import Foundation


class KLMUpdateManager {
    
    //单例
    static let sharedInstacnce = KLMUpdateManager()
    private init(){}   
    
    /// 获取bin文件
    /// - Returns: NSData
    func getProjectData() -> NSData? {
        
        guard let path = Bundle.main.path(forResource: "Project", ofType: "bin") else { return nil }
        return NSData.init(contentsOfFile: path)
        
    }
    
    //一个包n个字节 375
//    let DataK = 256
    
    /// 将bin拆成多个DataK大小的集合
    /// - Returns: 16进制字符串集合
    func dealFirmware(data: Int? = 256) -> [String] {
        
        //数据源
        let datas = self.getProjectData()!
        
        let dataLength = datas.length
        ///总包数
        var dataPackageFrame = 0
        
        var dataPackageArray = [String]()
        
        if dataLength % data! == 0{
            
            dataPackageFrame = dataLength / data!
        } else {
            
            dataPackageFrame =  dataLength / data!+1
        }

        for i in 0..<dataPackageFrame {
            
            if i < dataPackageFrame-1 {
                let subData = datas.subdata(with: NSRange(location: data! * i, length: data!))
                let dataHexString = subData.hexadecimal()
                dataPackageArray.append(dataHexString)
                
            }else if i == dataPackageFrame-1 {
                
                let subData = datas.subdata(with: NSRange(location: data! * i, length: dataLength - data!*i))
                let dataHexString = subData.hexadecimal()
                dataPackageArray.append(dataHexString)
            }
            
        }
        
        return dataPackageArray
    }
    
    /// 发送第一包的数据
    /// - Returns: 4个字节包长度+2个字节的crc校验值 16进制字符串
    func getUpdateFirstPackage() -> String {
        
        let datas = self.getProjectData()!
        ///整个包的crc校验值
        let crc16 = datas.crc16()
        
        var lenght = datas.length
        let lengthData = NSData.init(bytes: &lenght, length: 4)
        var length32: UInt32 = 0
        lengthData.getBytes(&length32, length: 4)
        //小端转大端
        length32 = NSSwapHostIntToBig(length32)
        let lengthD = NSData.init(bytes: &length32, length: 4)
        
        let index = Data.init(hex: "01")
        var data = Data()
        data.append(index)
        data.append(lengthD as Data)
        data.append(crc16)
        let dataHexString = data.hexadecimal()
        return dataHexString
    }
}
