//
//  KLMExportViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/9/13.
//

import UIKit
import nRFMeshProvision

class KLMExportViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    @IBAction func Export(_ sender: Any) {
        
        let manager = MeshNetworkManager.instance
        DispatchQueue.global(qos: .userInitiated).async {
            let data = manager.export(.full)
            
            do {
                let name = manager.meshNetwork?.meshName ?? "mesh"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name).json")
                try data.write(to: fileURL)
                
                DispatchQueue.main.async {
                    let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    controller.completionWithItemsHandler = { type, success, items, error in
                        if success {
                            self.dismiss(animated: true)
                        } else {
                            if let error = error {
                                print("Export failed: \(error)")
                                SVProgressHUD.showError(withStatus: "Exporting Mesh Network configuration failed "
                                                            + "with error \(error.localizedDescription).")
                            }
                        }
                    }
                    self.present(controller, animated: true)
                }
            } catch {
                print("Export failed: \(error)")
                DispatchQueue.main.async {
                    SVProgressHUD.showError(withStatus: "Exporting Mesh Network configuration failed "
                                                + "with error \(error.localizedDescription).")
                }
            }
        }
    }
}
