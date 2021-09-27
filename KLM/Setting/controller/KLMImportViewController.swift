//
//  KLMImportViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/9/13.
//

import UIKit
import nRFMeshProvision

class KLMImportViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

    @IBAction func `import`(_ sender: Any) {
        
        let picker = UIDocumentPickerViewController(documentTypes: ["public.data", "public.content"], in: .import)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension KLMImportViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let manager = MeshNetworkManager.instance
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                _ = try manager.import(from: data)
                self.saveAndReload()
            } catch let DecodingError.dataCorrupted(context) {
                let path = context.codingPath.path
                print("Import failed: \(context.debugDescription) (\(path))")
                DispatchQueue.main.async {
                    SVProgressHUD.showError(withStatus: "Importing Mesh Network configuration failed.\n"
                                                + "\(context.debugDescription)\nPath: \(path).")
                    
                }
            } catch let DecodingError.keyNotFound(key, context) {
                let path = context.codingPath.path
                print("Import failed: Key \(key) not found in \(path)")
                DispatchQueue.main.async {
                    SVProgressHUD.showError(withStatus: "Importing Mesh Network configuration failed.\n"
                                                + "No value associated with key: \(key.stringValue) in: \(path).")
                    
                }
            } catch let DecodingError.valueNotFound(value, context) {
                let path = context.codingPath.path
                print("Import failed: Value of type \(value) required in \(path)")
                DispatchQueue.main.async {
                    SVProgressHUD.showError(withStatus: "Importing Mesh Network configuration failed.\n"
                                                + "No value associated with key: \(path).")
                    
                }
            } catch let DecodingError.typeMismatch(type, context) {
                let path = context.codingPath.path
                print("Import failed: Type mismatch in \(path) (\(type) was required)")
                DispatchQueue.main.async {
                    SVProgressHUD.showError(withStatus: "Importing Mesh Network configuration failed.\n"
                                                + "Type mismatch in: \(path). Expected: \(type).")
                    
                }
            } catch {
                print("Import failed: \(error)")
                DispatchQueue.main.async {
                    SVProgressHUD.showError(withStatus: "Importing Mesh Network configuration failed.\n"
                                                + "Check if the file is valid.")
                    
                }
            }
        }
    }
    
}

extension KLMImportViewController {
    
    func saveAndReload() {
        
        let manager = MeshNetworkManager.instance
        if manager.save() {
            
            //更改provisioner 的 unicastAddress
//            let meshNetwork = manager.meshNetwork!
//            let provisioner: Provisioner =  (meshNetwork.provisioners.first)!
//            let nextAddress: Address = (meshNetwork.nextAvailableUnicastAddress(for: provisioner))!
//            print(nextAddress.asString())
//
//            do {
//                try meshNetwork.assign(unicastAddress: nextAddress, for: provisioner)
//                // Add the new addresses to the Proxy Filter.
//                let unicastAddresses = provisioner.node!.elements.map { $0.unicastAddress }
//                manager.proxyFilter?.add(addresses: unicastAddresses)
//            } catch  {
//                SVProgressHUD.showError(withStatus: "Mesh configuration could not be saved.")
//            }
            
//            if manager.save() {
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
                    SVProgressHUD.showSuccess(withStatus: "Mesh Network configuration imported.")
                    
                }
                
//            } else {
//                SVProgressHUD.showError(withStatus: "Mesh configuration could not be saved.")
//            }
        
        } else {
            SVProgressHUD.showError(withStatus: "Mesh configuration could not be saved.")
            
        }
    }
}

private extension Array where Element == CodingKey {
    
    var path: String {
        return reduce("root") { (result, node) -> String in
            if let range = node.stringValue.range(of: #"(\d+)$"#,
                                                  options: .regularExpression) {
                return "\(result)[\(node.stringValue[range])]"
            }
            return "\(result)→\(node.stringValue)"
        }
    }
    
}
