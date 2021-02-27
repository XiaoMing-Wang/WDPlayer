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
    
    fileprivate weak var delegate: WPPlayerViewBarProtocol? = nil
    fileprivate weak var content: UIView? = nil
    fileprivate var isFull: Bool = false
    fileprivate var isShowToolBar: Bool = true
    fileprivate var isProgressClosure: Bool = false

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
            guard isProgressClosure == false else { return }
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
        animationView.addSubview(blackView)
        animationView.addSubview(progressTimeLabel)
        animationView.addSubview(suspendButton)
        animationView.addSubview(fullButton)
        automaticLayout()
    }

    fileprivate func automaticLayout() {
        guard youTbProgress.superview != nil else { return }
        let height = isFull ? WDPlayerConf.toolSliderHeight + WDPlayerConf.safeBottom() + 10 : WDPlayerConf.toolSliderHeight
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
            make.center.equalToSuperview().offset(WDPlayerConf.toolSliderHeight * 0.5)
            make.width.height.equalTo(52)
        }
    }
    
    /**< 全屏布局 */
    public func fullConstraint(full: Bool = true) {
        self.isFull = full
        self.youTbProgress.isFull = full
        self.automaticLayout()
        self.layoutIfNeededAnimate()
    }

    /**< 展示 */
    func show() {
        guard isShowToolBar == false else { return }
        if isFull {
            
        } else {
            animationView.alpha = 0
            animationView.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.animationView.alpha = 1
            }
        }
//
//
//
//
//        alpha = 0
//        isHidden = false
//        if isFull {
//            youTbProgress.alpha = 0
//            youTbProgress.isHidden = false
//        }
//
//        UIView.animate(withDuration: 0.25) {
//            self.alpha = 1
//            self.isHidden = false
//            self.isShowThumb = true
//            self.youTbProgress.alpha = 1
//            self.youTbProgress.isHidden = false
//        }
        
        isShowThumb = true
        isShowToolBar = true
    }

    /**< 隐藏 */
    func hide(duration: TimeInterval = 0.25) {
        guard isShowToolBar else { return }
//        alpha = 1
//        isHidden = false
//        UIView.animate(withDuration: 0.25) {
//            self.alpha = 0
//            self.isFull ? (self.youTbProgress.alpha = 0) : (self.isShowThumb = self.isFull)
//        } completion: { _ in
//            self.alpha = 1
//            self.isHidden = true
//            if self.isFull {
//                self.youTbProgress.alpha = 1
//                self.youTbProgress.isHidden = true
//            }
//        }
//
        if isFull {
            
            
        } else {
            animationView.alpha = 1
            animationView.isHidden = false
            UIView.animate(withDuration: duration) {
                self.animationView.alpha = 0
            } completion: { _ in
                self.animationView.alpha = 1
                self.animationView.isHidden = true
            }
        }
        
        isShowThumb = false
        isShowToolBar = false
    }
    
    /**< 设置时间 */
    func progressTime() {
        progressTimeLabel.text = WDPlayerAssistant.timeTranslate(currentlTime) + " / " + WDPlayerAssistant.timeTranslate(totalTime)
    }
    
    /**< 动画转换 */
    fileprivate func layoutIfNeededAnimate(duration: TimeInterval = WDPlayerConf.playerAnimationDuration) {
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
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
        suspendButton.setImage(UIImage(named: "player_playbig"), for: .selected)
        suspendButton.setImage(UIImage(named: "player_pausebig"), for: .normal)
        suspendButton.addTarget(self, action: #selector(suspendClick), for: .touchUpInside)
        return suspendButton
    }()
    
    public lazy var animationView: UIView = {
        var animationView = UIView()
        animationView.clipsToBounds = false
        return animationView
    }()

    public lazy var blackView: UIView = {
        var blackView = UIView()
        blackView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        blackView.isUserInteractionEnabled = false
        return blackView
    }()
    
    public lazy var youTbProgress: WDPlayerViewYouTbProgress = {
        var youTbProgress = WDPlayerViewYouTbProgress(delegate: self.delegate)
        youTbProgress.progressClosure = { [weak self] in
            self?.isProgressClosure = $1
            self?.currentlTime = $0
            self?.progressTime()
        }
        return youTbProgress
    }()
}

class WDPlayerViewYouTbProgress: UIView {
    
    var progressClosure: ((Int, Bool) -> ())? = nil
    fileprivate weak var delegate: WPPlayerViewBarProtocol? = nil
    fileprivate var isFull: Bool = false
    fileprivate var progressTimeWidth: CGFloat = 0
    fileprivate var screenWidth: CGFloat = 0
    
    convenience init (delegate: WPPlayerViewBarProtocol?) {
        self.init()
        self.delegate = delegate
        self.initializationInterface()
        self.isUserInteractionEnabled = true
    }

    /**< 显示滑块 */
    fileprivate var isShowThumb: Bool = false {
        didSet {
            progressSlider.setThumbImage(UIImage(named: isShowThumb ? "sliderBlue" : "sliderBlueMin"), for: .normal)
        }
    }

    /**< 总时间 */
    fileprivate var totalTime: Int = 0 {
        didSet {
            setProgress()
            progressTime()
        }
    }

    /**< 当前时间 */
    fileprivate var currentlTime: Int = 0 {
        didSet {
            setProgress()
            progressTime()
        }
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
        addSubview(progressTimeLabel)
        automaticLayout()
    }
    
    fileprivate func setProgress() {
        if progressSlider.isTracking { return }
        guard totalTime > 0 else { return }
        let progress = Float(currentlTime) / Float(totalTime)
        progressSlider.value = progress
        moveThumb()
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
        
        progressTimeLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(20)
            make.bottom.equalTo(snp.top)
        }
    }

    /**< 滑动 */
    @objc func eventValueChanged() {
        delegate?.cancelHideToolbar()
        currentlTime = Int(progressSlider.value * Float(totalTime))

        if progressSlider.isTracking {
            
            if isShowThumb == false { progressTimeLabel.isHidden = false }
            progressClosure?(currentlTime, true)
            progressSlider.setThumbImage(UIImage(named: "sliderBlue"), for: .normal)
            moveThumb()
            
        } else {
            
            progressTimeLabel.isHidden = true
            progressClosure?(currentlTime, false)
            delegate?.eventValueChanged(currentlTime: currentlTime)
            if isFull == false && isShowThumb == false {
                progressSlider.setThumbImage(UIImage(named: "sliderBlueMin"), for: .normal)
            }
        }
    }
    
    func progressTime() {
        progressTimeLabel.text = WDPlayerAssistant.timeTranslate(currentlTime) + " / " + WDPlayerAssistant.timeTranslate(totalTime)
    }
    
    func moveThumb() {
        if progressTimeWidth <= 0 { return }
        let margin = (progressTimeWidth / 2 + 20)
        var centerX = screenWidth * CGFloat(progressSlider.value)
        if centerX < margin { centerX = margin }
        if centerX > screenWidth - margin { centerX = screenWidth - margin }
        progressTimeLabel.snp.remakeConstraints { (make) in
            make.centerX.equalTo(centerX)
            make.bottom.equalTo(snp.top)
        }
    }
    
    override func layoutSubviews() {
        screenWidth = frame.size.width
        progressTimeWidth = progressTimeLabel.frame.size.width
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

    fileprivate lazy var progressTimeLabel: UILabel = {
        var progressTimeLabel = UILabel()
        progressTimeLabel.textAlignment = .center
        progressTimeLabel.font = .systemFont(ofSize: 12)
        progressTimeLabel.textColor = .white
        progressTimeLabel.numberOfLines = 1
        progressTimeLabel.isHidden = true
        return progressTimeLabel
    }()
}

