//
//  WDPlayerViewYouTbBar.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/26.
//

import UIKit

class WDPlayerViewYouTbContent: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let response = super.hitTest(point, with: event)
        if point.y >= frame.size.height && point.y <= frame.size.height + 10 {
            if let slider = viewWithTag(1888) {
                return slider
            }
        }
        return response
    }
}

class WDPlayerViewYouTbBar: UIView {
    
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
            progressTime()
            youTbProgress.totalTime = totalTime
        }
    }

    /**< 当前时间 */
    public var currentlTime: Int = 0 {
        didSet {
            progressTime()
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
    
    /**< 显示滑块 */
    public var isShowThumb: Bool = false {
        didSet {
            youTbProgress.isShowThumb = isShowThumb
        }
    }
    
    /**< 暂停 */
    public var isSuspended: Bool = false {
        didSet {
            suspendButton.isSelected = isSuspended
        }
    }
    
    fileprivate weak var delegate: WPPlayerViewBarProtocol? = nil
    fileprivate weak var content: UIView? = nil
    fileprivate var isFull: Bool = false
    fileprivate var isShowToolBar: Bool = true
    
    fileprivate var minCententX: CGFloat = 0
    fileprivate var maxCententX: CGFloat = 0
    fileprivate var progressWidth: CGFloat = 0
    fileprivate var progressLeft: CGFloat = 0
    convenience init (content: UIView?, delegate: WPPlayerViewBarProtocol?) {
        self.init()
        self.content = content
        self.delegate = delegate
        self.initializationInterface()
        self.hide(duration: 0)
    }

    fileprivate func initializationInterface() {
        addSubview(animationView)
        addSubview(youTbProgress)
        addSubview(thumView)
        animationView.addSubview(blackView)
        animationView.addSubview(progressTimeLabel)
        animationView.addSubview(suspendButton)
        animationView.addSubview(fullButton)
        automaticLayout()
    }

    fileprivate func automaticLayout() {
        guard youTbProgress.superview != nil else { return }
        let height = isFull ? WDPlayerConf.toolSliderHeight + WDPlayerConf.safeBottom() + 10: WDPlayerConf.toolSliderHeight
        youTbProgress.snp.remakeConstraints { (make) in
            if self.isFull == false {
                make.left.right.bottom.equalTo(0)
                make.height.equalTo(height)
            } else {
                make.left.equalTo(WDPlayerConf.playerToolMargin + 10)
                make.right.equalTo(-WDPlayerConf.playerToolMargin - 10)
                make.bottom.equalTo(0)
                make.height.equalTo(height)
            }
        }

        thumView.snp.remakeConstraints { (make) in
            make.width.equalTo(WDPlayerConf.thumbnailWidth)
            make.height.equalTo(WDPlayerConf.thumbnailWidth * (9 / 16.0) + 25)
            make.bottom.equalTo(youTbProgress.snp.top).offset(0)
            make.centerX.equalTo(0)
        }

        animationView.snp.remakeConstraints { (make) in
            make.left.right.top.equalTo(0)
            make.bottom.equalTo(youTbProgress.snp.top).priority(.high)
        }

        blackView.snp.remakeConstraints { (make) in
            make.left.right.top.equalTo(0)
            make.bottom.equalTo(animationView).offset(height)
        }

        progressTimeLabel.snp.remakeConstraints { (make) in
            make.left.equalTo((isFull ? 70 : 20))
            make.bottom.equalTo(0)
        }

        if fullButton.superview != nil {
            fullButton.snp.remakeConstraints { (make) in
                make.right.equalTo(isFull ? -60 : -8)
                make.centerY.equalTo(progressTimeLabel)
                make.width.height.equalTo(WDPlayerConf.toolBarHeight)
            }
        }

        suspendButton.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview().offset(WDPlayerConf.toolSliderHeight * 0.5)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(52)
        }
    }
    
    /**< 全屏布局 */
    public func fullConstraint(full: Bool = true) {
        self.isFull = full
        self.automaticLayout()
        self.layoutIfNeededAnimate()
    }

    /**< 展示 */
    func show(duration: TimeInterval = 0.25) {
        if isShowToolBar == true { return }
        if isFull {
            WDPlayerAssistant.animationShow(self, duration: duration)
        } else {
            WDPlayerAssistant.animationShow(animationView, duration: duration)
        }
        isShowThumb = true
        isShowToolBar = true
    }

    /**< 隐藏 */
    func hide(duration: TimeInterval = 0.25) {
        if isShowToolBar == false { return }
        if isFull {
            isShowThumb = true
            WDPlayerAssistant.animationHiden(self, duration: duration)

        } else {
            isShowThumb = false
            WDPlayerAssistant.animationHiden(animationView, duration: duration)
        }

        isShowToolBar = false
    }
    
    /**< 设置时间 */
    func progressTime() {
        progressTimeLabel.text = WDPlayerAssistant.timeTranslate(currentlTime) + " / " + WDPlayerAssistant.timeTranslate(totalTime)
    }

    /**< 滑块回调 */
    func sliderCallback(currentlTime: Int, moving: Bool) {
        guard progressWidth > 0 else { return }
        let width_gap = (WDPlayerConf.thumbnailWidth * 0.5) + (isFull ? 0 : 10)
        let minValue = (progressLeft) + width_gap
        let maxValue = (progressLeft + progressWidth) - width_gap
        delegate?.cancelHideToolbar()
        
        if moving == true {
            let progress = CGFloat(currentlTime) / CGFloat(totalTime)
            let coordinates = progressLeft + progressWidth * progress
            let centerX = min(max(coordinates, minValue), maxValue)

            delegate?.currentImage(currentTime: currentlTime, results: { self.thumView.currentlImage = $0 })
            thumView.isHidden = false
            thumView.currentlTime = currentlTime
            thumView.snp.updateConstraints { (make) in
                make.centerX.equalTo(centerX)
            }

            if isShowToolBar {
                WDPlayerAssistant.animationHiden(suspendButton)
                centerX <= minCententX ? WDPlayerAssistant.animationHiden(progressTimeLabel) : WDPlayerAssistant.animationShow(progressTimeLabel)
            }

        } else {

            self.currentlTime = currentlTime
            thumView.isHidden = true
            delegate?.eventValueChanged(currentlTime: currentlTime, moving: false)
            if isShowToolBar {
                WDPlayerAssistant.animationShow(suspendButton)
                WDPlayerAssistant.animationShow(progressTimeLabel)
                WDPlayerAssistant.animationShow(fullButton)
            }
        }
    }
            
    /**< 动画转换 */
    fileprivate func layoutIfNeededAnimate(duration: TimeInterval = WDPlayerConf.playerAnimationDuration) {
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }
    
    @objc func full() {
        fullButton.isSelected = !fullButton.isSelected
        delegate?.fullEvent(isFull: fullButton.isSelected)
    }
        
    @objc func suspendClick() {
        suspendButton.isSelected = !suspendButton.isSelected
        isSuspended = suspendButton.isSelected
        delegate?.suspended(isSuspended: isSuspended)
        isSuspended ? delegate?.cancelHideToolbar() : delegate?.hiddenBar(hidden: true, isAnimation: false)
    }
    
    /**< 点击穿透 */
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let response = super.hitTest(point, with: event)
        if point.y >= frame.size.height - 20 && point.y <= frame.size.height + 10 {
            if let slider = viewWithTag(1888) {
                return slider
            }
        }
        
        if response == youTbProgress || response?.superview == youTbProgress { return youTbProgress.progressSlider }
        if response == fullButton { return fullButton }
        if response == suspendButton { return suspendButton }
        return nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        progressWidth = youTbProgress.frame.size.width
        progressLeft = youTbProgress.frame.origin.x
        minCententX = progressTimeLabel.frame.size.width + progressTimeLabel.frame.origin.x + 25
        maxCententX = progressWidth - fullButton.frame.origin.x - 20
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
        suspendButton.setImage(UIImage(named: "player_playbig"), for: .selected)
        suspendButton.setImage(UIImage(named: "player_pausebig"), for: .normal)
        suspendButton.addTarget(self, action: #selector(suspendClick), for: .touchUpInside)
        return suspendButton
    }()
    
    /**< 暂停等按钮 */
    fileprivate lazy var animationView: UIView = {
        var animationView = UIView()
        animationView.clipsToBounds = false
        return animationView
    }()

    /**< 黑色背景 */
    fileprivate lazy var blackView: UIView = {
        var blackView = UIView()
        blackView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        blackView.isUserInteractionEnabled = false
        return blackView
    }()

    /**< 缩图 */
    fileprivate lazy var thumView: WDPlayerThumView = {
        var thumView = WDPlayerThumView(delegate: delegate)
        thumView.isHidden = true
        return thumView
    }()

    /**< 进度条 */
    public lazy var youTbProgress: WDPlayerViewYouTbProgress = {
        var youTbProgress = WDPlayerViewYouTbProgress(delegate: nil)
        youTbProgress.progressClosure = { [weak self] in
            self?.sliderCallback(currentlTime: $0, moving: $1)
        }
        return youTbProgress
    }()
}

class WDPlayerViewYouTbProgress: UIView {

    var progressClosure: ((Int, Bool) -> ())? = nil
    convenience init (delegate: WPPlayerViewBarProtocol?) {
        self.init()
        self.initializationInterface()
        self.isUserInteractionEnabled = true
    }

    /**< 显示滑块 */
    fileprivate var isShowThumb: Bool = false {
        didSet { progressSlider.setThumbImage(UIImage(named: isShowThumb ? "sliderBlue" : "sliderBlueMin"), for: .normal)  }
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
            make.top.equalTo(WDPlayerConf.toolSliderHeight - 2.5)
            make.height.equalTo(2.5)
        }

        progressSlider.snp.remakeConstraints { (make) in
            make.left.equalTo(-1)
            make.right.equalTo(1)
            make.height.equalTo(WDPlayerConf.toolSliderHeight)
            make.centerY.equalTo(progressView).offset(-1.5)
        }
    }

    /**< 滑动 */
    @objc func eventValueChanged() {
        currentlTime = Int(progressSlider.value * Float(totalTime))
        if progressSlider.isTracking {

            /**< 滑动中 */
            progressClosure?(currentlTime, true)
            progressSlider.setThumbImage(UIImage(named: "sliderBlue"), for: .normal)

        } else {

            /**< 滑动结束 */
            progressClosure?(currentlTime, false)
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

    fileprivate lazy var progressSlider: WDPlayerViewSlider = {
        var slider = WDPlayerViewSlider()
        slider.minimumTrackTintColor = UIColor(red: 0 / 255.0, green: 191 / 255.0, blue: 255 / 255.0, alpha: 1)
        slider.addTarget(self, action: #selector(eventValueChanged), for: .valueChanged)
        slider.setThumbImage(UIImage(named: "sliderBlueMin"), for: .normal)
        slider.tag = 1888
        return slider
    }()
}

