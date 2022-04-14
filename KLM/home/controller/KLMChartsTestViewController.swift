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
    @IBOutlet weak var pieView: PieChartView!
    
    var data: BarChartData!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCharts()
        
        setupPieView()
        
        updateData()
    }
    
    func setupPieView() {
        
        pieView.chartDescription.text = "区域统计"
        pieView.backgroundColor = .lightGray
        pieView.usePercentValuesEnabled = true ///使用百分比
        ///区块文本
        pieView.drawEntryLabelsEnabled = true
        pieView.entryLabelColor = .white
        
        ///空心
        pieView.drawHoleEnabled = true
        pieView.holeRadiusPercent = 0.382
        pieView.drawCenterTextEnabled = true
        pieView.centerText = "区域人数"
        
        //图例样式设置
        pieView.legend.maxSizePercent = 1
        pieView.legend.form = .circle
        pieView.legend.font = UIFont.systemFont(ofSize: 10)
        pieView.legend.textColor = .orange
        pieView.legend.horizontalAlignment = .left
        pieView.legend.verticalAlignment = .top
        
        pieView.animate(xAxisDuration: 1, yAxisDuration: 1, easingOption: .easeInBack)
        
        updatePieData()
    }
    
    func updatePieData() {
        
        let titles = ["红","黄","蓝色","橙","绿"]
        let yData = [20,30,10,40,60]
        var yVals = [PieChartDataEntry]()
        for i in 0 ..< titles.count {
            let entry = PieChartDataEntry.init(value: Double(yData[i]), label: titles[i])
            yVals.append(entry)
        }
        
        //dataset
        let dataset = PieChartDataSet.init(entries: yVals, label: "区域记录")
        dataset.colors = [.red, .yellow, .blue, .orange, .green]
        dataset.valueFormatter = self
        dataset.xValuePosition = .insideSlice
        dataset.yValuePosition = .outsideSlice
        dataset.valueLinePart1OffsetPercentage = 0.8 //折线中第一段起始位置相对于区块的偏移量, 数值越大, 折线距离区块越远
        dataset.valueLinePart1Length = 0.6 //折线中第一段长度占比
        dataset.valueLinePart2Length = 0.3 //折线中第二段长度最大占比
        
        let data = PieChartData.init(dataSets: [dataset])
        pieView.data = data
        
    }

    func setupCharts() {

        chart.leftAxis.drawGridLinesEnabled = false
        chart.scaleXEnabled = false //关闭缩放
        chart.scaleYEnabled = false
        chart.backgroundColor = .yellow
        chart.chartDescription.text = "客流统计"
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
        
        if entry is BarChartDataEntry {
            return "\(Int(value))"
        }
        
        return String.init(format: "%.2f%%", value)
    }
}

