//
//  KLMImagePickerController.swift
//  KLM
//
//  Created by 朱雨 on 2021/7/7.
//

import UIKit
import Photos

class KLMImagePickerController: UIImagePickerController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///发送闪灯
        sendFlash()

        self.delegate = self
        
        self.showsCameraControls = false
        let overLayView = UIView.init(frame: self.view.bounds)
        overLayView.backgroundColor = .clear
        self.cameraOverlayView = overLayView
        
        //拍照
        let takePhotoBtn = UIButton.init(type: .custom)
//        takePhotoBtn.setTitle("拍照", for: .normal)
        takePhotoBtn.backgroundColor = .white
        takePhotoBtn.layer.borderWidth = 7
        takePhotoBtn.layer.borderColor = rgb(129, 129, 129).cgColor
        takePhotoBtn.layer.cornerRadius = 40
        takePhotoBtn.clipsToBounds = true
        takePhotoBtn.addTarget(self, action: #selector(takePicture), for: .touchUpInside)
        overLayView.addSubview(takePhotoBtn)
        takePhotoBtn.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-30)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        
        //关闭
        let closeBtn = UIButton.init()
        closeBtn.setImage(UIImage(named: "icon_camera_close"), for: .normal)
        closeBtn.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        overLayView.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(30)
            make.width.height.equalTo(30)
        }
        
        ///标题
        let titleLab: UILabel = UILabel.init()
        titleLab.font = UIFont.systemFont(ofSize: 15)
        titleLab.textColor = .white
        titleLab.text = LANGLOC("lightSet")
        overLayView.addSubview(titleLab)
        titleLab.snp.makeConstraints { make in
            make.centerY.equalTo(closeBtn)
            make.centerX.equalToSuperview()
        }
        
        //相册
        let libraryBtn = UIButton.init(type: .custom)
        libraryBtn.layer.cornerRadius = 5
        libraryBtn.clipsToBounds = true
        libraryBtn.addTarget(self, action: #selector(libraryClick), for: .touchUpInside)
        overLayView.addSubview(libraryBtn)
        libraryBtn.snp.makeConstraints { make in
            
            make.centerY.equalTo(takePhotoBtn)
            make.left.equalToSuperview().offset(40)
            make.height.equalTo(40)
            make.width.equalTo(40)
        }      
        
        if let latest = self.latestAsset() {
            
            DispatchQueue.global().async{
                
                PHImageManager.default().requestImage(for: latest, targetSize: .zero, contentMode: .aspectFill, options: nil) { result, info in
                    
                    DispatchQueue.main.async{
                        
                        libraryBtn.setImage(result, for: .normal)
                        
                    }
                }
            }
            
        } else {
            
            libraryBtn.setTitle(LANGLOC("library"), for: .normal)
            libraryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            libraryBtn.setTitleColor(.white, for: .normal)
        }
        
        //自定义
        let customBtn = UIButton.init(type: .custom)
        customBtn.setTitle(LANGLOC("custom"), for: .normal)
        customBtn.setImage(UIImage.init(named: "icon_customize"), for: .normal)
        customBtn.titleLabel?.font = UIFont.systemFont(ofSize: 11)
        customBtn.setTitleColor(.white, for: .normal)
        customBtn.addTarget(self, action: #selector(customClick), for: .touchUpInside)
        overLayView.addSubview(customBtn)
        customBtn.snp.makeConstraints { make in
            
            make.centerY.equalTo(takePhotoBtn)
            make.right.equalToSuperview().offset(-30)
            make.height.equalTo(70)
            make.width.equalTo(80)
        }
        customBtn.layoutButton(with: .top, imageTitleSpace: 7)
    }
    
    //灯闪烁
    func sendFlash() {
        
        let parame = parameModel(dp: .flash, value: 1)
        
        if KLMHomeManager.sharedInstacnce.controllType == .Device {

            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

        } else if KLMHomeManager.sharedInstacnce.controllType == .Group {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {

            } failure: { error in

            }
        }
    }
    
    @objc func closeClick() {
        
        let string = "000002"

        let parame = parameModel(dp: .recipe, value: string)
        
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {
                
                
            } failure: { error in
                
                
            }
        } else if KLMHomeManager.sharedInstacnce.controllType == .Device {

            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)

        } else {
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {

            } failure: { error in
                
            }
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @objc func libraryClick() {
        
        let imagePickerVc = UIImagePickerController()
        imagePickerVc.delegate = self
        imagePickerVc.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePickerVc.modalPresentationStyle = .fullScreen
        present(imagePickerVc, animated: true, completion: nil)
        
    }
    
    @objc func customClick() {
        
        let vc = KLMCustomViewController()
        let nav = KLMNavigationViewController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)

    }
    //获取相册最近一张照片
    func latestAsset() -> PHAsset? {
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        let assetsFetchResults = PHAsset.fetchAssets(with: options)
        return assetsFetchResults.firstObject ?? nil
    }
}

extension KLMImagePickerController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        var image:UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        image = UIImage.fixOrientation(image)
        
        let photoVc = KLMPhotoEditViewController()
        photoVc.originalImage = image
        let nav = KLMNavigationViewController(rootViewController: photoVc)
        nav.modalPresentationStyle = .fullScreen
        picker.present(nav, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
