//
//  WPPlayerViewToolbar.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit

/**< 工具栏回调 */
protocol WPPlayerViewBarDelegate: class {

    /// 进度回调
    /// - Parameter currentlTime: currentlTime
    func eventValueChanged(currentlTime: Int)

    /// 暂停回调
    /// - Parameter isSuspended: isSuspended
    func suspended(isSuspended: Bool)

    /// 取消隐藏工具栏
    func cancelHideToolbar()

    /// 点击返回按钮
    func backClick()

    /// 点击全屏按钮
    func fullClick(isFull: Bool)
}

class WPPlayerViewToolBar: UIView {

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
    
    /**< 支持横屏 */
    var isSupportFullScreen: Bool = true {
        didSet {
            if isSupportFullScreen == false {
                fullButton.snp.removeConstraints()
                fullButton.removeFromSuperview()
                endLabel.snp.removeConstraints()
                endLabel.text = "44:44"
                endLabel.sizeToFit()
                endLabel.text = "00:00"
                endLabel.snp.remakeConstraints { (make) in
                    make.right.equalToSuperview().offset(-15)
                    make.centerY.equalTo(suspendButton)
                    make.width.equalTo(endLabel.frame.size.width)
                }
            }
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
        clipsToBounds = !full
    }

    /**< 重置 */
    func reset() {
        progressView.progress = 0
        progressSlider.value = 0
        startLabel.text = "00:00"
    }
     
    fileprivate weak var delegate: WPPlayerViewBarDelegate? = nil
    var suspendClosure: ((Bool) -> Void)? = nil
    var cancelClosure: (() -> Void)? = nil

    convenience init (totalTime: Int, delegate: WPPlayerViewBarDelegate?) {
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
        bottomShadow.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(0)
            make.left.equalTo(-60)
            make.right.equalTo(60)
        }
        
        suspendButton.snp.makeConstraints { (make) in
            make.left.top.equalTo(0)
            make.width.height.equalTo(WDPlayerConf.toolBarHeight)
        }

        let width = startLabel.frame.size.width
        startLabel.text = "00:00"
        startLabel.snp.makeConstraints { (make) in
            make.left.equalTo(suspendButton.snp.right).offset(3)
            make.width.equalTo(width)
            make.centerY.equalTo(suspendButton)
        }

        fullButton.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.top.equalTo(0)
            make.width.height.equalTo(suspendButton)
        }

        let endWidth = endLabel.frame.size.width
        endLabel.text = "00:00"
        endLabel.snp.makeConstraints { (make) in
            make.right.equalTo(fullButton.snp.left).offset(-3)
            make.centerY.equalTo(suspendButton)
            make.width.equalTo(endWidth)
        }

        touchButton.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.height.equalTo(suspendButton)
            make.left.equalTo(startLabel.snp.right).offset(10)
            make.right.greaterThanOrEqualTo(endLabel.snp.left).offset(-10)
        }

        progressView.snp.makeConstraints { (make) in
            make.height.equalTo(3)
            make.left.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }

        progressSlider.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
    }
    
    /**< 设置进度 */
    fileprivate func setProgress() {
        guard totalTime > 0 else { return }
        let progress = Float(currentlTime) / Float(totalTime)
        progressSlider.value = progress
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


