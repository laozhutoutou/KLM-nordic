//
//  KLMWifiSelectViewController.swift
//  KLM
//
//  Created by 朱雨 on 2022/7/29.
//

import UIKit

typealias wifiBlock = (_ model: KLMWiFiModel) -> Void

class KLMWifiSelectViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelBtn: UIButton!
    
    var WiFiLists: [KLMWiFiModel]!
    var wifiBlock: wifiBlock?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cancelBtn.layer.cornerRadius = cancelBtn.height / 2
        cancelBtn.backgroundColor = .lightGray.withAlphaComponent(0.5)
        
        WiFiLists = KLMWiFiManager.getWifiLists() ?? [KLMWiFiModel]()
    }

    @IBAction func setNetworks(_ sender: Any) {
        
        guard let url = URL(string: "App-prefs:WIFI")  else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        dismiss(animated: true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension KLMWifiSelectViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return WiFiLists.count

    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return 40
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = WiFiLists[indexPath.row]
        let cell: KLMTableViewCell = KLMTableViewCell.cellWithTableView(tableView: tableView)
        cell.isShowLeftImage = false
        cell.leftTitle = model.WiFiName
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = WiFiLists[indexPath.row]
        if let wifi = wifiBlock {
            wifi(model)
        }
        dismiss(animated: true)
    }
}
