//
//  KLMChartsTestViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/4/2.
//

import UIKit
import Charts

class KLMChartsTestViewController: UIViewController {
    
    @IBOutlet weak var chart: BarChartView!
    var data: BarChartData!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCharts()
        
        updateData()
    }

    func setupCharts() {

        chart.leftAxis.drawGridLinesEnabled = false
        chart.scaleXEnabled = false //关闭缩放
        chart.scaleYEnabled = false
        chart.backgroundColor = .yellow
//        view.addSubview(chart)
        
        ///刷新图表
//        barChartView.notifyDataSetChanged()
//        barChartView.data?.notifyDataChanged()

        ///Y轴 左侧
        let leftAxis = chart.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 20
        leftAxis.drawGridLinesEnabled = false //左侧y轴设置，不画线
//        leftAxis.labelCount = 5
//        leftAxis.axisLineColor = .red
//        let numberFormatter = NumberFormatter.init()
//        numberFormatter.positiveSuffix = "$"
//        leftAxis.valueFormatter = DefaultAxisValueFormatter.init(formatter: numberFormatter)
        
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
        let days = ["\(nowTime - 4)", "\(nowTime - 3)", "\(nowTime - 2)", "\(nowTime - 1)", "当前"]
        chart.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        
        
        let values = [7, 10, 3, 15, 12]

        var dataEntris: [BarChartDataEntry] = []
        for (idx, _) in days.enumerated() {
            let dataEntry = BarChartDataEntry(x: Double(idx), y: Double(values[idx]))
            dataEntris.append(dataEntry)
        }
        let chartDataSet = BarChartDataSet(entries: dataEntris, label: "人数")
        chartDataSet.valueFormatter = self
        
        ///柱状的颜色
//        chartDataSet.setColor(.blue)
        
        let chartData = BarChartData(dataSet: chartDataSet)
        ///柱状上文字大小
        chartData.setValueFont(UIFont.systemFont(ofSize: 10))
        ///柱状宽度
        chartData.barWidth = 0.5
        self.data = chartData
        
        chart.data = chartData
        chart.animate(yAxisDuration: 0.4)
    
    }
    
    @IBAction func update(_ sender: Any) {
        
        let dataset: BarChartDataSet = data.dataSet(at: 0) as! BarChartDataSet
        let datas: BarChartDataEntry = dataset[4] as! BarChartDataEntry
        KLMLog(" y1 = \(datas.y)")
        datas.y = 4
        KLMLog(" y2 = \(datas.y)")
        ///dataset最大值等才会更新
        dataset.notifyDataSetChanged()
        ///data最大值等才会更新
        self.data.notifyDataChanged()
        ///图表刷新
        self.chart.notifyDataSetChanged()
        KLMLog("yMax = \(dataset.yMax)")
        KLMLog("dataYmax = \(self.data.yMax)")
    
    }
    
}

extension KLMChartsTestViewController: ValueFormatter {
    
    ///
    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        
        return "\(Int(value))"
    }
}

//extension KLMChartsTestViewController: AxisValueFormatter {
//
//    func stringForValue(_ value: Double,
//                        axis: AxisBase?) -> String {
//
//        return "小时\(value)"
//    }
//}
