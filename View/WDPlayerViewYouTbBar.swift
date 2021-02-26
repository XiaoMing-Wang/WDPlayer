//
//  WDPlayerViewYouTbBar.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/26.
//

import UIKit

class WDPlayerViewYouTbBar: UIView {

    fileprivate weak var delegate: WPPlayerViewBarProtocol? = nil
    fileprivate weak var content: UIView? = nil
    fileprivate var isFull: Bool = false

    /**< 支持横屏 */
    public var isSupportFullScreen: Bool = true {
        didSet {
            if isSupportFullScreen == false {
                fullButton.removeFromSuperview()
            } else {
                addSubview(fullButton)
            }
            automaticLayout()
        }
    }
    
    /**< 总时间 */
    public var totalTime: Int = 0 {
        didSet {
            progressTimeLabel.text = WDPlayerAssistant.timeTranslate(currentlTime) + " / " + WDPlayerAssistant.timeTranslate(totalTime)
            youTbProgress.totalTime = totalTime
        }
    }

    /**< 当前时间 */
    public var currentlTime: Int = 0 {
        didSet {
            progressTimeLabel.text = WDPlayerAssistant.timeTranslate(currentlTime) + " / " + WDPlayerAssistant.timeTranslate(totalTime)
            youTbProgress.currentlTime = currentlTime
        }
    }
    
    /**< 缓冲 */
    public var bufferTime: Int = 0 {
        didSet {
            guard totalTime > 0 else { return }
            youTbProgress.bufferTime = bufferTime
        }
    }
    
    /**< 暂停 */
    public var isSuspended: Bool = false {
        didSet {
            suspendButton.isSelected = isSuspended
        }
    }

    convenience init (content: UIView?, delegate: WPPlayerViewBarProtocol?) {
        self.init()
        self.content = content
        self.delegate = delegate
        self.initializationInterface()
    }

    fileprivate func initializationInterface() {
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        content?.addSubview(youTbProgress)
        addSubview(progressTimeLabel)
        addSubview(suspendButton)
        addSubview(fullButton)
        automaticLayout()
    }

    fileprivate func automaticLayout() {
        let x = (isFull ? 70 : 20)
        let y = (isFull ? -WDPlayerConf.safeBottom() - 35 : -20)
        progressTimeLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(x)
            make.bottom.equalTo(y)
        }

        suspendButton.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(52)
        }

        if fullButton.superview != nil {
            fullButton.snp.remakeConstraints { (make) in
                make.right.equalTo(-5 - x)
                make.centerY.equalTo(progressTimeLabel)
                make.width.height.equalTo(WDPlayerConf.toolBarHeight)
            }
        }

        if youTbProgress.superview != nil {
            youTbProgress.snp.remakeConstraints { (make) in
                if self.isFull == false {
                    make.left.right.bottom.equalTo(0)
                    make.height.equalTo(18)
                } else {
                    make.left.equalTo(WDPlayerConf.playerToolMargin + 8)
                    make.right.equalTo(-WDPlayerConf.playerToolMargin - 8)
                    make.height.equalTo(18)
                    make.bottom.equalTo(-WDPlayerConf.safeBottom() - 10)
                }
            }
        }
        
        
    }
    
    /**< 全屏布局 */
    public func fullConstraint(full: Bool = true) {
        self.isFull = full
        self.automaticLayout()
        self.layoutIfNeededAnimate()
        self.youTbProgress.fullConstraint(full: full)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.hideToolbar()
    }
    
    /**< 动画转换 */
    fileprivate func layoutIfNeededAnimate(duration: TimeInterval = WDPlayerConf.playerAnimationDuration) {
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }

    @objc func full() {
        fullButton.isSelected = !fullButton.isSelected
        delegate?.fullClick(isFull: fullButton.isSelected)
    }
    
    @objc func suspendClick() {
        suspendButton.isSelected = !suspendButton.isSelected
        isSuspended = suspendButton.isSelected
        delegate?.suspended(isSuspended: isSuspended)
        isSuspended ? delegate?.cancelHideToolbar() : delegate?.hideToolbar()
    }

    fileprivate lazy var progressTimeLabel: UILabel = {
        var progressTimeLabel = UILabel()
        progressTimeLabel.textAlignment = .center
        progressTimeLabel.font = .systemFont(ofSize: 12)
        progressTimeLabel.textColor = .white
        progressTimeLabel.numberOfLines = 1
        progressTimeLabel.text = "00:00 / 00: 00"
        return progressTimeLabel
    }()
    
    fileprivate lazy var fullButton: UIButton = {
        var fullButton = UIButton()
        fullButton.setImage(UIImage(named: "player_fullscreen"), for: .normal)
        fullButton.addTarget(self, action: #selector(full), for: .touchUpInside)
        return fullButton
    }()
    
    fileprivate lazy var suspendButton: UIButton = {
        var suspendButton = UIButton()
        suspendButton.setImage(UIImage(named: "player_play"), for: .selected)
        suspendButton.setImage(UIImage(named: "player_pause"), for: .normal)
        suspendButton.addTarget(self, action: #selector(suspendClick), for: .touchUpInside)
        return suspendButton
    }()

    public lazy var youTbProgress: WDPlayerViewYouTbProgress = {
        var youTbProgress = WDPlayerViewYouTbProgress(delegate: self.delegate)
        return youTbProgress
    }()
}

class WDPlayerViewYouTbProgress: UIView {
    
    fileprivate weak var delegate: WPPlayerViewBarProtocol? = nil
    fileprivate var isFull: Bool = false
    convenience init (delegate: WPPlayerViewBarProtocol?) {
        self.init()
        self.delegate = delegate
        self.initializationInterface()
    }
    
    /**< 总时间 */
    fileprivate var totalTime: Int = 0 {
        didSet { setProgress() }
    }

    /**< 当前时间 */
    fileprivate var currentlTime: Int = 0 {
        didSet { setProgress() }
    }

    /**< 缓冲 */
    fileprivate var bufferTime: Int = 0 {
        didSet {
            guard totalTime > 0 else { return }
            let ratio = Float(bufferTime) / Float(totalTime)
            progressView.setProgress(ratio, animated: true)
        }
    }

    fileprivate func initializationInterface() {
        addSubview(progressView)
        addSubview(progressSlider)
        automaticLayout()
    }
    
    fileprivate func setProgress() {
        if progressSlider.isTracking { return }
        guard totalTime > 0 else { return }
        let progress = Float(currentlTime) / Float(totalTime)
        progressSlider.value = progress
    }

    fileprivate func automaticLayout() {
        progressView.snp.remakeConstraints { (make) in
            make.left.equalTo(0)
            make.right.equalTo(0)
            make.bottom.equalTo(0)
            make.height.equalTo(2.5)
        }

        progressSlider.snp.remakeConstraints { (make) in
            make.left.right.equalTo(0)
            make.height.equalTo(20)
            make.centerY.equalTo(progressView).offset(-1.5)
        }
    }
    
    public func fullConstraint(full: Bool = true) {
        isFull = full
        progressSlider.setThumbImage(UIImage(named: full ? "sliderBlue" : "sliderBlueMin"), for: .normal)
    }

    /**< 滑动 */
    @objc func eventValueChanged() {
        if progressSlider.isTracking {
            progressSlider.setThumbImage(UIImage(named: "sliderBlue"), for: .normal)
        } else if isFull == false {
            let currentlTime = Int(progressSlider.value * Float(totalTime))
            progressSlider.setThumbImage(UIImage(named: "sliderBlueMin"), for: .normal)
            delegate?.eventValueChanged(currentlTime: currentlTime)
        }
    }
    
    fileprivate lazy var progressView: UIProgressView = {
        var progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0
        progressView.progressTintColor = UIColor.white.withAlphaComponent(0.5)
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        progressView.isUserInteractionEnabled = false
        return progressView
    }()
    
    fileprivate lazy var progressSlider: UISlider = {
        var slider = UISlider()
        slider.minimumTrackTintColor = UIColor(red: 0 / 255.0, green: 191 / 255.0, blue: 255 / 255.0, alpha: 1)
        slider.addTarget(self, action: #selector(eventValueChanged), for: .valueChanged)
        slider.setThumbImage(UIImage(named: "sliderBlueMin"), for: .normal)
        return slider
    }()
    
    
}
