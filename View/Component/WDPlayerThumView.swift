//
//  WDPlayerThumView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/3/1.
//

import UIKit

class WDPlayerThumView: UIView {
    
    public var currentlTime: Int = 0 {
        didSet {
            progressTimeLabel.text = WDPlayerAssistant.timeTranslate(currentlTime)
        }
    }

    public var currentlImage: UIImage? = nil {
        didSet {
            thumbnailImageView.image = currentlImage
            indicatorView.isHidden = true
            indicatorView.stopAnimating()
        }
    }
    
    fileprivate weak var delegate: WPPlayerViewBaseProtocol? = nil
    convenience init (delegate: WPPlayerViewBaseProtocol?) {
        self.init()
        self.initialize()
    }
    
    func initialize() {
        thumbnailImageView.addSubview(indicatorView)
        addSubview(thumbnailImageView)
        addSubview(progressTimeLabel)
        automaticLayout()
    }

    fileprivate func automaticLayout() {
        thumbnailImageView.snp.remakeConstraints { (make) in
            make.top.equalTo(0)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(snp.width).multipliedBy((9.0 / 16.0))
        }

        progressTimeLabel.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        indicatorView.snp.remakeConstraints { (make) in
            make.width.height.equalTo(20)
            make.center.equalToSuperview()
        }
    }

    fileprivate lazy var thumbnailImageView: UIImageView = {
        var thumbnailImageView = UIImageView()
        thumbnailImageView.layer.cornerRadius = 4
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.backgroundColor = UIColor.gray.withAlphaComponent(1)
        return thumbnailImageView
    }()

    public lazy var indicatorView: UIActivityIndicatorView = {
        var indicatorView = UIActivityIndicatorView(style: .white)
        indicatorView.startAnimating()
        return indicatorView
    }()
    
    public lazy var progressTimeLabel: UILabel = {
        var progressTimeLabel = UILabel()
        progressTimeLabel.textAlignment = .center
        progressTimeLabel.font = .systemFont(ofSize: 12)
        progressTimeLabel.textColor = .white
        progressTimeLabel.numberOfLines = 1
        progressTimeLabel.text = "00:00"
        return progressTimeLabel
    }()

}
