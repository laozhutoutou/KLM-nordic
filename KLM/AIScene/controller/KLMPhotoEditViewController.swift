//
//  KLMPhotoEditViewController.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/3.
//

import UIKit

class KLMPhotoEditViewController: UIViewController {
    
    var originalImage: UIImage!
    var startPoint: CGPoint!
    @IBOutlet weak var lightBgView: UIView!
    
    @IBOutlet weak var lightLab: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    //图像数据
    var imageData: UnsafeMutablePointer<UInt8>!
    
    var lightSlider: KLMSlider!
    //当前配方
    var currentRecipe: Int = 0 {
        
        didSet {
            
            self.lightBgView.isHidden = false
            lightLab.isHidden = false
            
            self.lightSlider.isUserInteractionEnabled = true
            //完成
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: LANGLOC("finish"), target: self, action: #selector(finish))  
        }
    }
    //当前亮度
    var lightValue: Int = 100
    
    var isFinish = false
    
    lazy var tapView: UIImageView = {
        let image = UIImage(named: "icon_photo_tap")
        let tapView = UIImageView(image: image)
        tapView.frame = CGRect(x: 0, y: 0, width: (image?.size.width)!, height: (image?.size.height)!)
        tapView.isHidden = true
        return tapView
    }()
    
    lazy var clipView: UIView = {
        let clipView = UIView()
        clipView.layer.borderColor = UIColor.white.cgColor
        clipView.layer.borderWidth = 2
        clipView.layer.shadowColor = UIColor.gray.cgColor
        clipView.layer.shadowRadius = 2
        clipView.layer.shadowOffset = CGSize.init(width: 0, height: 0)
        clipView.layer.shadowOpacity = 0.8
        return clipView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        KLMSmartNode.sharedInstacnce.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LANGLOC("lightSet")
        
        //导航栏左边添加返回按钮
        self.navigationItem.leftBarButtonItems = UIBarButtonItem.item(withBackIconTarget: self, action: #selector(dimiss)) as? [UIBarButtonItem]
        
        setupUI()
        
        imageData = self.originalImage.convert(toBitmapRGBA8: self.originalImage)
    }
    
    func setupUI() {
        
        imageView.image = originalImage
        
        //框选
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
        contentView.addGestureRecognizer(panRecognizer)
        
        //点选
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(tap:)))
        contentView.addGestureRecognizer(tapRecognizer)
        
        //亮度滑条
        let viewLeft: CGFloat = 20
        let sliderWidth = KLMScreenW - viewLeft * 2
        let lightSlider: KLMSlider = KLMSlider.init(frame: CGRect(x: 0, y: 0, width: sliderWidth, height: lightBgView.height), minValue: 0, maxValue: 100, step: 2)
        lightSlider.getValueTitle = { value in
//            let value = value
            return String(format: "%ld%%", Int(value))
        }
        lightSlider.currentValue = Float(self.lightValue)
        lightSlider.delegate = self
        self.lightSlider = lightSlider
        lightBgView.addSubview(lightSlider)
    }
    //点选
    @objc func handleTap(tap: UITapGestureRecognizer) {
        
        var tapPoint = tap.location(in: contentView)
        self.tapView.isHidden = false
        
        if tap.state == .ended {
            
            self.tapView.removeFromSuperview()
            contentView.addSubview(self.tapView)
            self.tapView.center = tapPoint
            clipView.removeFromSuperview()
            
            //控制
            //图片上的坐标点
            tapPoint = getImagePoint(point: tapPoint)
            
            let recipe = getRecipeIndexOfImageOnClick(imageData, Int32(self.originalImage.size.width), Int32(self.originalImage.size.height), IMAGE_FORMAT_RGBA, Int32(tapPoint.x), Int32(tapPoint.y))
            currentRecipe = Int(recipe)
            
            KLMLog("click = \(recipe)")
            setData()
        }
    }
    //框选
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        
        if pan.state == .began {
            
            self.tapView.removeFromSuperview()
            
            startPoint = pan.location(in: contentView)
            
            clipView.removeFromSuperview()
            contentView.addSubview(clipView)
        }else if pan.state == .changed {
            
            let curP = pan.location(in: contentView)
            let offsetX = curP.x - startPoint.x
            let offsetY = curP.y - startPoint.y
            clipView.frame = CGRect(x: startPoint.x, y: startPoint.y, width: offsetX, height: offsetY)
            
        }else if pan.state == .ended {
            
            let clipViewStart = getImagePoint(point: clipView.origin)
            let clipViewFinish = getImagePoint(point: CGPoint(x: self.clipView.origin.x + self.clipView.width, y: self.clipView.origin.y + self.clipView.height))
            
            let recipe = getRecipeIndexOfImageOnBox(imageData, Int32(self.originalImage.size.width), Int32(self.originalImage.size.height), IMAGE_FORMAT_RGBA, Int32(clipViewStart.x), Int32(clipViewStart.y), Int32(clipViewFinish.x), Int32(clipViewFinish.y))
            currentRecipe = Int(recipe)
            KLMLog("box = \(recipe)")
            setData()
        }
    }
    
    ///发送数据
    func setData() {
        
        isFinish = false
        
        //16进制字符串，2个字节，"121001"，12代表配方18，10代表亮度,00代表预览，01代表确定，02取消
        let recipeHex = self.currentRecipe.decimalTo2Hexadecimal()
        //亮度范围80-120
        let lightValueHex = self.lightValue.decimalTo2Hexadecimal()
        let string = recipeHex + lightValueHex + "00"
        
        let parame = parameModel(dp: .recipe, value: string)
        
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {
                
                print("success")
                
            } failure: { error in
                
                KLMShowError(error)
            }
        } else if KLMHomeManager.sharedInstacnce.controllType == .Device {

            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                print("success")
                
            } failure: { error in
                KLMShowError(error)
            }

        }
        
    }
    
    /// 屏幕上的点转化为图片上的坐标点
    /// - Parameter point: 屏幕上的点
    /// - Returns: 图片上的坐标点
    func getImagePoint(point: CGPoint) -> CGPoint {
        
        let imageRatio = self.originalImage.size.width / self.originalImage.size.height;
        
        let viewRatio = self.imageView.width / self.imageView.height;
        
        if(imageRatio < viewRatio)//图片竖直,宽能显示完
        {
            //宽度缩放比例
            let scale = self.imageView.width / self.originalImage.size.width;
            
            let imageX = point.x / scale;
            
            //imageview的起点在image中的位置
            let heightH = (scale * self.originalImage.size.height - self.imageView.height)/2.0;
            
            let imageY = (heightH + point.y) / scale;
            
            return CGPoint(x: imageX, y: imageY)
            
        }
        else//图片水平，高能显示完
        {
            let scale = self.imageView.height / self.originalImage.size.height;
            
            let imageY = point.y / scale;
            
            //imageview的起点在image中的位置
            let widthW = (scale * self.originalImage.size.width - self.imageView.width)/2.0;
            
            let imageX = (widthW + point.x) / scale;
            
            return CGPoint(x: imageX, y: imageY)
        }
    }
    
    @objc func dimiss() {
        
        isFinish = false
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @objc func finish() {
        
        SVProgressHUD.show()
        
        isFinish = true
        
        //保存当前设置
        //16进制字符串，2个字节，"121001"，12代表配方18，10代表亮度,00代表预览，01代表确定，02取消
        let recipeHex = self.currentRecipe.decimalTo2Hexadecimal()
        //亮度范围80-120
        let lightValueHex = self.lightValue.decimalTo2Hexadecimal()
        let string = recipeHex + lightValueHex + "01"
        
        
        let parame = parameModel(dp: .recipe, value: string)
        
        if KLMHomeManager.sharedInstacnce.controllType == .AllDevices {
            
            KLMSmartGroup.sharedInstacnce.sendMessageToAllNodes(parame) {
                
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                
                DispatchQueue.main.asyncAfter(deadline: 1) {
                    
                    //获取根VC
                    var  rootVC =  self.presentingViewController
                    while  let  parent = rootVC?.presentingViewController {
                        rootVC = parent
                    }
                    //释放所有下级视图
                    rootVC?.dismiss(animated:  true , completion:  nil )
                }
                
            } failure: { error in
                
                KLMShowError(error)
            }
        } else if KLMHomeManager.sharedInstacnce.controllType == .Device {
            
            KLMSmartNode.sharedInstacnce.sendMessage(parame, toNode: KLMHomeManager.currentNode)
            
        } else {
            
            KLMSmartGroup.sharedInstacnce.sendMessage(parame, toGroup: KLMHomeManager.currentGroup) {
                
                SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
                
                DispatchQueue.main.asyncAfter(deadline: 1) {
                    
                    //获取根VC
                    var  rootVC =  self.presentingViewController
                    while  let  parent = rootVC?.presentingViewController {
                        rootVC = parent
                    }
                    //释放所有下级视图
                    rootVC?.dismiss(animated:  true , completion:  nil )
                }
                
            } failure: { error in
                KLMShowError(error)
            }

        }
    }
}

extension KLMPhotoEditViewController: KLMSliderDelegate {
    
    func KLMSliderWith(slider: KLMSlider, value: Float) {
        self.lightValue = Int(value)
        setData()
    }
    
}

extension KLMPhotoEditViewController: KLMSmartNodeDelegate {
    
    func smartNode(_ manager: KLMSmartNode, didReceiveVendorMessage message: parameModel?) {
        if isFinish {
            
            SVProgressHUD.showSuccess(withStatus: LANGLOC("Success"))
            
            DispatchQueue.main.asyncAfter(deadline: 0.5) {
                
                //获取根VC
                var  rootVC =  self.presentingViewController
                while  let  parent = rootVC?.presentingViewController {
                    rootVC = parent
                }
                //释放所有下级视图
                rootVC?.dismiss(animated:  true , completion:  nil )
            }
        }
        
        print("success")
    }
    
    func smartNode(_ manager: KLMSmartNode, didfailure error: MessageError?) {
        KLMShowError(error)
    }
}
