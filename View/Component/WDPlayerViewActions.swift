//
//  WDPlayTouchActionView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/19.
//

import UIKit

class WDPlayFastForward: UIView {

    init() {
        super.init(frame: .zero)
        self.initializationInterface()
        self.automaticLayout()
    }

    var seconds: Int = 0 {
        didSet {
            iconImageView.image = UIImage(named: (seconds >= 0) ? "fastForward" : "retreatQuickly")
            secondsLabel.text = "\(abs(seconds)) S"
        }
    }

    var timeStamp: String? = nil {
        didSet {
            timeStampLabel.text = timeStamp
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func automaticLayout() {
        addSubview(iconImageView)
        addSubview(secondsLabel)
        addSubview(timeStampLabel)

        iconImageView.snp.makeConstraints { (make) in
            make.top.equalTo(5)
            make.right.equalTo(snp.centerX).offset(-3)
            make.width.height.equalTo(24)
        }

        secondsLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(5)
            make.centerY.equalTo(iconImageView)
        }

        timeStampLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.bottom.equalTo(-5)
        }
    }
    
    fileprivate func initializationInterface() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }
    
    public lazy var iconImageView: UIImageView = {
        var iconImageView = UIImageView()
        iconImageView.image = UIImage(named: "fastForward")
        return iconImageView
    }()

    fileprivate lazy var secondsLabel: UILabel = {
        var secondsLabel = UILabel()
        secondsLabel.textAlignment = .center
        secondsLabel.font = .systemFont(ofSize: 15)
        secondsLabel.textColor = .white
        secondsLabel.numberOfLines = 1
        secondsLabel.text = "100"
        secondsLabel.sizeToFit()
        return secondsLabel
    }()

    fileprivate lazy var timeStampLabel: UILabel = {
        var timeStampLabel = UILabel()
        timeStampLabel.textAlignment = .center
        timeStampLabel.font = .systemFont(ofSize: 11)
        timeStampLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        timeStampLabel.numberOfLines = 1
        timeStampLabel.text = "00:00 / 12:00"
        timeStampLabel.sizeToFit()
        return timeStampLabel
    }()
}

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
