//
//  extension.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/3.
//

import Foundation

extension UIView {
    
    public var height: CGFloat {
        get {
            return frame.size.height
        }
        set {
            var rect = self.frame
            rect.size.height = newValue
            self.frame = rect
        }
    }
    
    public var width: CGFloat {
        get {
            return frame.size.width
        }
        set {
            var rect = self.frame
            rect.size.width = newValue
            self.frame = rect
        }
    }
    
    public var x: CGFloat {
        get {
            return frame.origin.x
        }
        set {
            var rect = self.frame
            rect.origin.x = newValue
            self.frame = rect
        }
    }
    
    public var y: CGFloat {
        get {
            return frame.origin.y
        }
        set {
            var rect = self.frame
            rect.origin.y = newValue
            self.frame = rect
            
        }
    }
    
    var origin:CGPoint {
        get {
            return self.frame.origin
        }
        set(newValue) {
            var rect = self.frame
            rect.origin = newValue
            self.frame = rect
        }
    }
    
    var size:CGSize {
        get {
            return self.frame.size
        }
        set(newValue) {
            var rect = self.frame
            rect.size = newValue
            self.frame = rect
        }
    }
}

extension DispatchTime: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = DispatchTime.now() + .seconds(value)
    }
}

extension DispatchTime: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = DispatchTime.now() + .milliseconds(Int(value * 1000))
    }
}

extension NSNotification.Name {
    ///设备添加
    static let deviceAddSuccess = NSNotification.Name.init("deviceAddSuccess")
    ///设备转移
    static let deviceTransferSuccess = NSNotification.Name.init("deviceTransferSuccess")
    /// 群组删除
    static let groupDeleteSuccess = NSNotification.Name.init("groupDeleteSuccess")
    /// 群组重命名
    static let groupRenameSuccess = NSNotification.Name.init("groupRenameSuccess")
    /// 群组添加
    static let groupAddSuccess = NSNotification.Name.init("groupAddSuccess")
    /// 设备从组中移除
    static let deviceRemoveFromGroup = NSNotification.Name.init("deviceRemoveFromGroup")
    /// 设备添加到群组
    static let deviceAddToGroup = NSNotification.Name.init("deviceAddToGroup")
    /// 设备名称修改
    static let deviceNameUpdate = NSNotification.Name.init("deviceNameUpdate")
    /// 设备删除成功
    static let deviceReset = NSNotification.Name.init("deviceReset")
    
    static let refreshDeviceEdit = NSNotification.Name.init("refreshDeviceEdit")
    
    ///家庭
    static let homeAddSuccess = NSNotification.Name.init("homeAddSuccess")
    static let homeDeleteSuccess = NSNotification.Name.init("homeDeleteSuccess")
    static let dataUpdate = NSNotification.Name.init("dataUpdate")
}

extension String {
    
    /// 十六进制 -> 十进制
    /// - Returns: 十进制
    func hexadecimalToDecimal() -> String {
        let str = self.uppercased()
        var sum = 0
        for i in str.utf8 {
            // 0-9 从48开始
            sum = sum * 16 + Int(i) - 48
            // A-Z 从65开始，但有初始值10，所以应该是减去55
            if i >= 65 {
                sum -= 7
            }
        }
        return "\(sum)"
    }
    
    /// 16进制字符串转化成color
    /// - Returns: color
    func hexToColor() -> UIColor {
        
        if self.count == 12 {
            
            let HH = self.substring(to: 4)
            let SS = self[4,4]
            let BB = self.substring(from: 8)
            
            let H: Float = Float(HH.hexadecimalToDecimal())! / 360
            let S: Float = Float(SS.hexadecimalToDecimal())! / 1000
            let B: Float = Float(BB.hexadecimalToDecimal())! / 1000
            if H == 0 && S == 0 && B == 0{
                
                return .white
            }
            
            return UIColor.init(hue: CGFloat(H), saturation: CGFloat(S), brightness: CGFloat(B), alpha: 1)
        }
        return .white
    }
    
}

extension String {
    
    /// String使用下标截取字符串
    /// string[index] 例如："abcdefg"[3] // c
    subscript (i:Int)->String{
        let startIndex = self.index(self.startIndex, offsetBy: i)
        let endIndex = self.index(startIndex, offsetBy: 1)
        return String(self[startIndex..<endIndex])
    }
    /// String使用下标截取字符串
    /// string[index..<index] 例如："abcdefg"[3..<4] // d
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound)
            return String(self[startIndex..<endIndex])
        }
    }
    /// String使用下标截取字符串
    /// string[index,length] 例如："abcdefg"[3,2] // de
    subscript (index:Int , length:Int) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let endIndex = self.index(startIndex, offsetBy: length)
            return String(self[startIndex..<endIndex])
        }
    }
    // 截取 从头到i位置
    func substring(to:Int) -> String{
        return self[0..<to]
    }
    // 截取 从i到尾部
    func substring(from:Int) -> String{
        return self[from..<self.count]
    }
}


extension Data {
    
    /// nsdata转换成16进制字符串
    /// - Returns: 16进制字符串
    func hexadecimal() -> String {
        return map { String(format: "%02x", $0) }
                    .joined(separator: "")
    }
    
    ///大小端转化
    mutating func convertToLittleEndian() -> String {
        
        var dataList: [UInt8] = []
        //倒序
        for i in self.bytes.reversed() {
            dataList.append(i)
        }
        let data = Data.init(bytes: dataList, count: dataList.count)
        return data.toHexString().uppercased()
    }
}

extension Int {
    
    /// 十进制转16进制 1个字节
    /// - Returns: 16进制字符串
    func decimalTo2Hexadecimal() -> String {
        
        return String(format: "%02X", self)
    }
    
    /// 十进制转16进制 2个字节
    /// - Returns: 16进制字符串
    func decimalTo4Hexadecimal() -> String {
        
        return String(format: "%04X", self)
    }
}

extension UIColor {
    
    /// color转化成16进制字符串 HSB
    /// - Returns: 16进制字符串
    func colorToHexString() -> String {
        
        var a: CGFloat = 1
        var H: CGFloat = 0
        var S: CGFloat = 0
        var B: CGFloat = 0
        self.getHue(&H, saturation: &S, brightness: &B, alpha: &a)
        
        let HH = Int(H * 360).decimalTo4Hexadecimal()
        let SS = Int(S * 1000).decimalTo4Hexadecimal()
        let BB = Int(B * 1000).decimalTo4Hexadecimal()
        KLMLog("H = \(H * 360), S = \(S * 1000), B = \(B * 1000)")
        return HH + SS + BB
    }
}

extension Dictionary {
    
    func jsonPrint() -> String {
        
        var string = ""
        do {
            try string = String.init(data: JSONSerialization.data(withJSONObject: self, options: .prettyPrinted), encoding: .utf8) ?? ""
            
        } catch {
            
            print(error)
        }
        return string
    }
}

