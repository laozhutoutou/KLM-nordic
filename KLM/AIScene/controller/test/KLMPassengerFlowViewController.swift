//
//  KLMPassengerFlowViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/2/21.
//

import UIKit
import SVProgressHUD
import Charts

class KLMPassengerFlowViewController: UIViewController {
    
    @IBOutlet weak var passengerView: UIView!
    @IBOutlet weak var numLab: UILabel!
    
    var imageView: UIImageView!
    
    var chart: BarChartView!
    var days: [String] = []
    
    var currentValues: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        KLMSmartNode.sharedInstacnce.delegate = self
          
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = LANGLOC("Customer Counting")
        
        setupCharts()
        
//        setupPic()
        
    }
    
    private func setupPic() {
        
        imageView = UIImageView.init(frame: CGRect.init(x: 0, y: 210, width: KLMScreenW, height: 300))
        view.addSubview(imageView)
    }

    @IBAction func getPassenger(_ sender: Any) {
        
        SVProgressHUD.show()
        let parame = parameModel(dp: .passengerFlow)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
                
    }
    
    private func setupCharts() {

        chart = BarChartView.init(frame: CGRect.init(x: 10, y: 150, width: 300, height: 300))
        chart.leftAxis.drawGridLinesEnabled = false
        chart.scaleXEnabled = false //关闭缩放
        chart.scaleYEnabled = false
        view.addSubview(chart)
        
        ///刷新图表
//        barChartView.notifyDataSetChanged()
//        barChartView.data?.notifyDataChanged()

        ///Y轴 左侧
        let leftAxis = chart.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 20
        leftAxis.drawGridLinesEnabled = false //左侧y轴设置，不画线
//        leftAxis.labelTextColor =
//        leftAxis.labelFont
        
        ///Y轴 右侧
        let rightAxis = chart.rightAxis
        rightAxis.enabled = false  //不绘制右边轴
        
        ///X轴
        let xAxis = chart.xAxis
        xAxis.labelPosition = .bottom //x轴的位置
        xAxis.drawGridLinesEnabled = false //不显示网格线
        xAxis.granularity = 1.0 //x轴label对齐柱状条
        
    }
    
    func updateData() {
        
        let date = Date()
        let timeFormatter = DateFormatter()
        //日期显示格式，可按自己需求显示
        timeFormatter.dateFormat = "HH:mm"
        let strNowTime = timeFormatter.string(from: date) as String
        
        var model = passengerRecode.recodeModel()
        model.date = strNowTime
        model.num = currentValues
        
        ///记录最近的3条记录
        let key = "passengerRecode" + KLMHomeManager.currentNode.UUIDString
        if var ree = KLMCache.getCache(passengerRecode.self, key: key) { ///有缓存
            if ree.list.count >= 3 {
                ree.list.removeFirst()
            }
            ree.list.append(model)
            KLMCache.setCache(model: ree, key: key)
        } else { ///没有缓存
            
            var recode = passengerRecode()
            recode.list.append(model)
            KLMCache.setCache(model: recode, key: key)
        }
        
        let result = KLMCache.getCache(passengerRecode.self, key: key)
        
        /// X轴label
        days = result!.list.map({ item in
            return item.date!
        })
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        
        /// Y值
        let values = result!.list.map({ item in
            return item.num!
        })

        var dataEntris: [BarChartDataEntry] = []
        for (idx, _) in days.enumerated() {
            let dataEntry = BarChartDataEntry(x: Double(idx), y: Double(values[idx]))
            dataEntris.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(entries: dataEntris, label: "Number of people")
        chartDataSet.valueFormatter = self
        ///柱状的颜色
//        chartDataSet.setColor(.blue)
        
        let chartData = BarChartData(dataSet: chartDataSet)
        ///柱状上文字大小
        chartData.setValueFont(UIFont.systemFont(ofSize: 10))
        ///柱状宽度
        chartData.barWidth = 0.5
        
        chart.data = chartData
        chart.animate(yAxisDuration: 0.4)
    
    }
}

extension KLMPassengerFlowViewController: ValueFormatter {
    
    ///
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        
        return "\(Int(value))"
    }
}

extension KLMPassengerFlowViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp ==  .passengerFlow, let value = message?.value as? Int {//查询版本
            
            currentValues = value
            numLab.text = "\(value)"
            
            updateData()
        }
        
        if message?.dp == .cameraPic{
            
            if let data = message?.value as? [UInt8], data.count >= 4 {
                
                let ip: String = "http://\(data[0]).\(data[1]).\(data[2]).\(data[3])/bmp"
                KLMLog("ip = \(ip)")
                let url = URL.init(string: ip)
                
                /// forceRefresh 不需要缓存
                imageView.kf.indicatorType = .activity
                imageView.kf.setImage(with: url, placeholder: nil, options: [.forceRefresh]) { result in

                    switch result {
                    case .success(let value):
                        // The image was set to image view:
                        print(value.image)

                        ///测试使用 - 保存图片到相册
                        SVProgressHUD.show(withStatus: "保存到手机")
                        UIImageWriteToSavedPhotosAlbum(value.image, self, #selector(self.saveImage(image:didFinishSavingWithError:contextInfo:)), nil)

                    case .failure(let error):
                        print(error) // The error happens
                    }
                }
            }
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
    
    @objc private func saveImage(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
            var showMessage = ""
            if error != nil{
                showMessage = "保存失败"
            }else{
                showMessage = "保存成功"
            }
            SVProgressHUD.showInfo(withStatus: showMessage)
        }
}

struct passengerRecode: Codable {
    
    var list: [recodeModel] = [recodeModel]()
    struct recodeModel: Codable {
        var num: Int?
        var date: String?
    }
}
