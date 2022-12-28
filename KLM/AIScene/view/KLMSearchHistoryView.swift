//
//  KLMSearchHistoryView.swift
//  KLM
//
//  Created by 朱雨 on 2021/6/8.
//

import UIKit

protocol KLMSearchHistoryViewDelegate: AnyObject {
    
    func KLMSearchHistoryViewDidSelectHistory(text: String)
    func KLMSearchHistoryClearAll()
}

class KLMSearchHistoryView: UIView, Nibloadable {
    
    @IBOutlet weak var historyLab: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    static var myframe: CGRect!
        
    var itemString: KLMHistory? {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    weak var delegate:  KLMSearchHistoryViewDelegate?
    
    //清除历史记录
    @IBAction func deleteClick(_ sender: Any) {
        
        self.delegate?.KLMSearchHistoryClearAll()
    }
    
    static func historyView(frame: CGRect) -> Self {
        
        let view = Self.loadNib()
        myframe = frame
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.collectionView.register(TagCell.self, forCellWithReuseIdentifier: "cell")
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        if #available(iOS 10.0, *) {
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }else {
            layout.estimatedItemSize = CGSize(width: 50, height: 50)
        }
        self.collectionView.collectionViewLayout =  layout
        
        historyLab.text = LANGLOC("History")
    }
    
    override func draw(_ rect: CGRect) {
        self.frame = KLMSearchHistoryView.myframe
    }
}

extension KLMSearchHistoryView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemString?.data.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TagCell
        let model = itemString?.data[indexPath.row]
        cell.tagLabel.text = model?.searchContent
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let model = itemString?.data[indexPath.row]
        self.delegate?.KLMSearchHistoryViewDidSelectHistory(text: model!.searchContent)
        
    }
}

class TagCell: UICollectionViewCell {
    lazy var tagLabel: UILabel = {
        let label = UILabel()
        label.textColor = rgba(38, 38, 38, 1)
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(7)
            make.center.equalToSuperview()
        }
        self.contentView.backgroundColor = appBackGroupColor
        self.layer.cornerRadius = 16
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

