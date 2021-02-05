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

class WPPlayerViewToolbar: UIView {

    /**< 总时间 */
    public var totalTime: Int = 0 {
        didSet {
            endLabel.text = WDPlayerAssistant.timeTranslate(totalTime)
        }
    }

    /**< 当前时间 */
    public var currentlTime: Int = 0 {
        didSet {
            if isTouching == false {
                startLabel.text = WDPlayerAssistant.timeTranslate(currentlTime)
                setProgress()
            }
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

    /**< 是否正在触摸 */
    fileprivate var isTouching: Bool = false
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
        addSubview(progressSlider)

        isUserInteractionEnabled = true
        clipsToBounds = true
        automaticLayout()
    }

    /// 布局
    fileprivate func automaticLayout() {
        bottomShadow.snp.makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.width.equalToSuperview()
            make.height.equalToSuperview().offset(40)
        }

        suspendButton.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.top.bottom.equalTo(0)
            make.width.equalTo(WDPlayConf.toolBarHeight)
        }

        let width = startLabel.width
        startLabel.text = "00:00"
        startLabel.snp.makeConstraints { (make) in
            make.left.equalTo(suspendButton.snp.right).offset(3)
            make.width.equalTo(width)
            make.centerY.equalTo(suspendButton)
        }

        fullButton.snp.makeConstraints { (make) in
            make.right.equalTo(0)
            make.top.bottom.equalTo(0)
            make.width.equalTo(WDPlayConf.toolBarHeight)
        }

        endLabel.snp.makeConstraints { (make) in
            make.right.equalTo(fullButton.snp.left).offset(-3)
            make.centerY.equalTo(suspendButton)
        }

        progressSlider.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(0)
            make.left.equalTo(startLabel.snp.right).offset(10)
            make.right.equalTo(endLabel.snp.left).offset(-10)
            make.centerY.equalTo(suspendButton).offset(-1)
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
    
    @objc func eventValueChanged() {
        isTouching = true
        if progressSlider.isTracking == false {
            let value = progressSlider.value
            let currentlTime = ceil(value * Float(totalTime))
            let currentlTimeInt = Int(currentlTime)
            self.currentlTime = currentlTimeInt
            self.startLabel.text = WDPlayerAssistant.timeTranslate(currentlTimeInt)
            self.progressSlider.isUserInteractionEnabled = false
            delegate?.eventValueChanged(currentlTime: currentlTimeInt)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.45) {
                self.isTouching = false
                self.progressSlider.isUserInteractionEnabled = true
            }
        }

        delegate?.cancelHideToolbar()
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
        endLabel.text = "00:00"
        return endLabel
    }()

    fileprivate lazy var fullButton: UIButton = {
        var fullButton = UIButton()
        fullButton.setImage(UIImage(named: "player_fullscreen"), for: .normal)
        fullButton.addTarget(self, action: #selector(full), for: .touchUpInside)
        return fullButton
    }()

    fileprivate lazy var progressSlider: UISlider = {
        var slider = UISlider()
        slider.minimumTrackTintColor = .white
        slider.addTarget(self, action: #selector(eventValueChanged), for: .valueChanged)
        slider.setThumbImage(UIImage(named: "sliderBtn"), for: .normal)
        return slider
    }()

}


