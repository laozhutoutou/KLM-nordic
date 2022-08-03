//
//  KLMTestImageCell.swift
//  KLM
//
//  Created by 朱雨 on 2022/8/1.
//

import UIKit
import Kingfisher

class KLMTestImageCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    var url: String? {
        didSet {
            let url = URL.init(string: url!)
            /// forceRefresh 不需要缓存
            imageView.kf.indicatorType = .activity            
            imageView.kf.setImage(with: url, placeholder: nil, options: [.forceRefresh]) { result in

                switch result {
                case .success(let value):
                    // The image was set to image view:
                    print(value.image)

                case .failure(let error):
                    print(error) // The error happens
                }
            }
        }
    }
    
    func setImageWith(url: String) {
        
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }

}
