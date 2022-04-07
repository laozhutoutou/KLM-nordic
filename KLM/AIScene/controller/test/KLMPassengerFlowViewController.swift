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
    
    var chart: BarChartView!
    var days: [String] = []
    
    var currentValues: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        KLMSmartNode.sharedInstacnce.delegate = self
          
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "客流统计"
        
        setupCharts()
        
    }

    @IBAction func getPassenger(_ sender: Any) {
        
        SVProgressHUD.show()
        let parame = parameModel(dp: .passengerFlow)
        KLMSmartNode.sharedInstacnce.readMessage(parame, toNode: KLMHomeManager.currentNode)
        
    }
    
    func setupCharts() {

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
        timeFormatter.dateFormat = "HH"
        let strNowTime = timeFormatter.string(from: date) as String
        let nowTime: Int = Int(strNowTime)!
        
        /// X轴label
        days = ["\(nowTime - 4)", "\(nowTime - 3)", "\(nowTime - 2)", "\(nowTime - 1)", "当前"]
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        
        
        let values = [7, 10, 3, 15, currentValues]

        var dataEntris: [BarChartDataEntry] = []
        for (idx, _) in days.enumerated() {
            let dataEntry = BarChartDataEntry(x: Double(idx), y: Double(values[idx]))
            dataEntris.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(entries: dataEntris, label: "人数")
        
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

extension KLMPassengerFlowViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        
        SVProgressHUD.dismiss()
        if message?.dp ==  .passengerFlow, let value = message?.value as? Int {//查询版本
            
            currentValues = value
            numLab.text = "\(value)"
            
            updateData()
        }
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
