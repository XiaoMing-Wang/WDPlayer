//
//  WDPlayTouchActionView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/19.
//

import UIKit

class WDPlayVolumeBrightness: UIView {

    enum VolumeBrightnessType {
        case volume
        case brightness
    }

    fileprivate var type: VolumeBrightnessType? = nil
    convenience init(type: VolumeBrightnessType = .brightness) {
        self.init()
        self.type = type
        self.initializationInterface()
    }

    /**< 进度 0-100  */
    public var progress: Int = 0 {
        didSet {
            progressView.progress = Float(progress) / Float(100)
            numericalLabel.text = "\(Int(progress))"
        }
    }

    public func progressFloat() -> CGFloat {
        return CGFloat(progressView.progress)
    }
    
    fileprivate func initializationInterface() {
        isUserInteractionEnabled = false
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        layer.cornerRadius = 5
        layer.masksToBounds = true
        iconImageView.image = (type == .volume) ? UIImage(named: "player_volume") : UIImage(named: "player_brightness")

        addSubview(iconImageView)
        addSubview(progressView)
        addSubview(numericalLabel)
        automaticLayout()
    }

    fileprivate func automaticLayout() {
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        
        let width = numericalLabel.frame.size.width
        numericalLabel.snp.makeConstraints { (make) in
            make.right.equalTo(-10)
            make.width.equalTo(width)
            make.height.equalToSuperview()
            make.top.equalTo(0)
        }

        progressView.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(6)
            make.right.equalTo(numericalLabel.snp.left).offset(-6)
            make.centerY.equalToSuperview()
            make.height.equalTo(3)
        }
    }

    public lazy var iconImageView: UIImageView = {
        var iconImageView = UIImageView()
        return iconImageView
    }()

    fileprivate lazy var progressView: UIProgressView = {
        var progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0
        progressView.progressTintColor = UIColor.white.withAlphaComponent(1)
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.5)
        progressView.isUserInteractionEnabled = false
        return progressView
    }()

    fileprivate lazy var numericalLabel: UILabel = {
        var numericalLabel = UILabel()
        numericalLabel.textAlignment = .center
        numericalLabel.font = .systemFont(ofSize: 12)
        numericalLabel.textColor = .white
        numericalLabel.numberOfLines = 1
        numericalLabel.text = "100"
        numericalLabel.sizeToFit()
        return numericalLabel
    }()
}