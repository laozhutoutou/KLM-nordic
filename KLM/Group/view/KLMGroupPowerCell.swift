//
//  KLMGroupPowerCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/3/7.
//

import UIKit

class KLMGroupPowerCell: KLMBaseTableViewCell {

    @IBOutlet weak var onBtn: UIButton!
    @IBOutlet weak var offBtn: UIButton!
    
    fileprivate var isFirst: Bool = true
    
    var isAllNodes: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        onBtn.layer.cornerRadius = 4.0
        offBtn.layer.cornerRadius = 4.0
        onBtn.clipsToBounds = true
        offBtn.clipsToBounds = true
        
        onBtn.layer.borderWidth = 1
        offBtn.layer.borderWidth = 1
        
        onBtn.layer.borderColor = UIColor.lightGray.cgColor
        offBtn.layer.borderColor = UIColor.lightGray.cgColor
        
        onBtn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
        onBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
        
        offBtn.setBackgroundImage(UIImage.init(color: .white), for: .normal)
        offBtn.setBackgroundImage(UIImage.init(color: appMainThemeColor), for: .selected)
    }
    
    @IBAction func onClick(_ sender: Any) {
        
        if onBtn.isSelected {
            return
        }
        
        if isCanClick() == false {
            
            return
        }
        
        let parame = parameModel(dp: .power, value: 1)
        if isAllNodes {
            
            SVProgressHUD.show()
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) { [weak self] in
                SVProgressHUD.dismiss()
                KLMLog("success")
                guard let self = self else { return }
                self.onBtn.isSelected = true
                self.offBtn.isSelected = false
            } failure: { error in
                KLMShowError(error)
            }

        } else {
            SVProgressHUD.show()
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) { [weak self] in
                SVProgressHUD.dismiss()
                KLMLog("success")
                guard let self = self else { return }
                self.onBtn.isSelected = true
                self.offBtn.isSelected = false
            } failure: { error in
                KLMShowError(error)
            }
        }
        
    }
    
    @IBAction func offClick(_ sender: Any) {
        
        if offBtn.isSelected {
            return
        }
        
        if isCanClick() == false {
            
            return
        }
        
        let parame = parameModel(dp: .power, value: 0)
        if isAllNodes {
            
            SVProgressHUD.show()
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) { [weak self] in
                SVProgressHUD.dismiss()
                KLMLog("success")
                guard let self = self else { return }
                self.onBtn.isSelected = false
                self.offBtn.isSelected = true
            } failure: { error in
                KLMShowError(error)
            }
            
        } else {
            
            SVProgressHUD.show()
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) { [weak self] in
                SVProgressHUD.dismiss()
                KLMLog("success")
                guard let self = self else { return }
                self.onBtn.isSelected = false
                self.offBtn.isSelected = true
            } failure: { error in
                KLMShowError(error)
            }
        }
    }
    
    fileprivate func isCanClick() -> Bool {
        
        if isFirst == true {
            
            isFirst = false
            
            DispatchQueue.main.asyncAfter(deadline: 10) {
                self.isFirst = true
                
            }
            return true
            
        } else {
            
            SVProgressHUD.showInfo(withStatus: "Please wait for 10 seconds")
            return false
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
