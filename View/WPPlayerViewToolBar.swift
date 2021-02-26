//
//  WPPlayerViewToolbar.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit

class WPPlayerViewToolBar: UIView {
    
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
            endLabel.text = WDPlayerAssistant.timeTranslate(totalTime)
            touchButton.isUserInteractionEnabled = true
        }
    }

    /**< 当前时间 */
    public var currentlTime: Int = 0 {
        didSet {
            if progressSlider.isTracking == false {
                startLabel.text = WDPlayerAssistant.timeTranslate(currentlTime)
                setProgress()
            }
        }
    }
    
    /**< 缓冲 */
    public var bufferTime: Int = 0 {
        didSet {
            guard totalTime > 0 else { return }
            let ratio = Float(bufferTime) / Float(totalTime)
            progressView.setProgress(ratio, animated: true)
        }
    }

    /**< 暂停 */
    public var isSuspended: Bool = false {
        didSet {
            suspendButton.isSelected = isSuspended
        }
    }
  
    /**< 全屏 */
    public var isFullScreen: Bool = false {
        didSet {
            fullButton.isSelected = isFullScreen
        }
    }
    
    /**< 全屏布局 */
    public func fullConstraint(full: Bool = true) {
        isFull = full
        automaticLayout()
        layoutIfNeededAnimate()
    }

    /**< 重置 */
    func reset() {
        progressView.progress = 0
        progressSlider.value = 0
        startLabel.text = "00:00"
        endLabel.text = "00:00"
    }
     
   
    fileprivate weak var delegate: WPPlayerViewBarProtocol? = nil
    fileprivate var isFull: Bool = false
    var suspendClosure: ((Bool) -> Void)? = nil
  
    convenience init (totalTime: Int, delegate: WPPlayerViewBarProtocol?) {
        self.init()
        self.delegate = delegate
        self.totalTime = totalTime
        self.initializationInterface()
    }

    /**< 初始化 */
    fileprivate func initializationInterface() {
        addSubview(bottomShadow)
        addSubview(suspendButton)
        addSubview(startLabel)
        addSubview(endLabel)
        addSubview(fullButton)
        addSubview(touchButton)
        touchButton.addSubview(progressView)
        touchButton.addSubview(progressSlider)

        isUserInteractionEnabled = true
        clipsToBounds = true
        automaticLayout()
    }

    /**< 布局 */
    fileprivate func automaticLayout() {
        bottomShadow.snp.remakeConstraints { (make) in
            make.top.bottom.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
        
        let margin = (isFull ? WDPlayerConf.playerToolMargin : 0)
        suspendButton.snp.remakeConstraints { (make) in
            make.left.equalTo(margin)
            make.top.equalTo(0)
            make.width.height.equalTo(WDPlayerConf.toolBarHeight)
        }

        let width = startLabel.frame.size.width
        startLabel.text = "00:00"
        startLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(suspendButton.snp.right).offset(3)
            make.width.equalTo(width)
            make.centerY.equalTo(suspendButton)
        }

        if fullButton.superview != nil {
            fullButton.snp.remakeConstraints { (make) in
                make.right.equalTo(-margin)
                make.top.equalTo(0)
                make.width.height.equalTo(suspendButton)
            }
        }
        
        let endWidth = endLabel.frame.size.width
        let isFull = (fullButton.superview != nil)
        endLabel.text = "00:00"
        endLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(suspendButton)
            make.width.equalTo(endWidth)
            if isFull { make.right.equalTo(fullButton.snp.left).offset(-3) }
            else { make.right.equalToSuperview().offset(-15) }
        }

        touchButton.snp.remakeConstraints { (make) in
            make.top.equalTo(0)
            make.height.equalTo(suspendButton)
            make.left.equalTo(startLabel.snp.right).offset(10)
            make.right.greaterThanOrEqualTo(endLabel.snp.left).offset(-10)
        }

        progressView.snp.remakeConstraints { (make) in
            make.height.equalTo(3)
            make.left.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }

        progressSlider.snp.remakeConstraints { (make) in
            make.edges.equalTo(0)
        }
    }
    
    /**< 动画转换 */
    fileprivate func layoutIfNeededAnimate(duration: TimeInterval = WDPlayerConf.playerAnimationDuration) {
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }
    
    /**< 设置进度 */
    fileprivate func setProgress() {
        guard totalTime > 0 else { return }
        let progress = Float(currentlTime) / Float(totalTime)
        progressSlider.setValue(progress, animated: true)
    }

    /**< 暂停 */
    @objc func suspendClick() {
        suspendButton.isSelected = !suspendButton.isSelected
        isSuspended = suspendButton.isSelected
        delegate?.suspended(isSuspended: isSuspended)
        delegate?.cancelHideToolbar()
    }
    
    /**< 点击 */
    @objc func eventTouchUpInside() {
        if progressSlider.isTracking { return }
        touchButton.isUserInteractionEnabled = false
        progressSlider.value = touchButton.clickProportions
        adjustProgressSlider()
        restoreUserInteractionEnabled()
    }

    /**< 滑动 */
    @objc func eventValueChanged() {
        delegate?.cancelHideToolbar()
        if progressSlider.isTracking == false {
            adjustProgressSlider()
        }
    }

    func adjustProgressSlider() {
        let value = progressSlider.value
        let currentlTime = ceil(value * Float(totalTime))
        let currentlTimeInt = Int(currentlTime)
        self.currentlTime = currentlTimeInt
       
        self.progressSlider.isUserInteractionEnabled = false
        delegate?.eventValueChanged(currentlTime: currentlTimeInt)
        delegate?.cancelHideToolbar()
        restoreUserInteractionEnabled()
    }

    func restoreUserInteractionEnabled() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.progressSlider.isUserInteractionEnabled = true
            self.touchButton.isUserInteractionEnabled = true
        }
    }

    @objc func full() {
        fullButton.isSelected = !fullButton.isSelected
        delegate?.fullClick(isFull: fullButton.isSelected)
    }

    fileprivate lazy var bottomShadow: UIImageView = {
        var bottomShadow = UIImageView()
        bottomShadow.image = UIImage(named: "player_bottom_shadow")
        return bottomShadow
    }()

    fileprivate lazy var suspendButton: UIButton = {
        var suspendButton = UIButton()
        suspendButton.setImage(UIImage(named: "player_pause"), for: .normal)
        suspendButton.setImage(UIImage(named: "player_play"), for: .selected)
        suspendButton.addTarget(self, action: #selector(suspendClick), for: .touchUpInside)
        return suspendButton
    }()

    fileprivate lazy var startLabel: UILabel = {
        var startLabel = UILabel()
        startLabel.textAlignment = .left
        startLabel.font = .systemFont(ofSize: 12)
        startLabel.textColor = .white
        startLabel.numberOfLines = 1
        startLabel.text = "44:44"
        startLabel.sizeToFit()
        return startLabel
    }()

    fileprivate lazy var endLabel: UILabel = {
        var endLabel = UILabel()
        endLabel.textAlignment = .left
        endLabel.font = .systemFont(ofSize: 12)
        endLabel.textColor = .white
        endLabel.numberOfLines = 1
        endLabel.text = "44:44"
        endLabel.sizeToFit()
        return endLabel
    }()

    fileprivate lazy var fullButton: UIButton = {
        var fullButton = UIButton()
        fullButton.setImage(UIImage(named: "player_fullscreen"), for: .normal)
        fullButton.addTarget(self, action: #selector(full), for: .touchUpInside)
        return fullButton
    }()

    fileprivate lazy var touchButton: WDPLayTouchButton = {
        var touchButton = WDPLayTouchButton()
        touchButton.addTarget(self, action: #selector(eventTouchUpInside), for: .touchUpInside)
        touchButton.isUserInteractionEnabled = false
        return touchButton
    }()
    
   
    fileprivate lazy var progressView: UIProgressView = {
        var progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0
        progressView.progressTintColor = UIColor.white.withAlphaComponent(0.5)
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.1)
        progressView.isUserInteractionEnabled = false
        return progressView
    }()

    fileprivate lazy var progressSlider: UISlider = {
        var slider = UISlider()
        slider.minimumTrackTintColor = .white
        slider.addTarget(self, action: #selector(eventValueChanged), for: .valueChanged)
        slider.setThumbImage(UIImage(named: "sliderBtn"), for: .normal)
        return slider
    }()
}

fileprivate class WDPLayTouchButton: UIButton {
    fileprivate var clickProportions: Float = 0
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if let slider = view as? UISlider {
            let center = convert(point, to: view)
            clickProportions = Float(center.x) / Float(slider.frame.size.width)
            let distance = abs(clickProportions - slider.value)
            return (distance <= 0.10) ? slider : self
        }
        return view
    }
}


