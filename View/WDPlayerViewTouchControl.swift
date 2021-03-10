//
//  WDPlayerTouchView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/5.
//

import UIKit
import MediaPlayer
import AVFoundation

class WDPlayerViewTouchControl: UIView {

    enum PanDirection {
        case free
        case horizontal    //水平
        case verticalLeft  //竖直左
        case verticalRight //竖直右
    }
    
    public var supportPanGestureRecognizer: Bool = WDPlayerConf.supportPanGestureRecognizer {
        didSet { removeAllGesturer() }
    }

    public var isSupportVolumeBrightness: Bool = true {
        didSet { }
    }
    
    public var supportDoubleClick: Bool = WDPlayerConf.supportDoubleClick {
        didSet { removeAllGesturer() }
    }

    public var supportToolbar: Bool = WDPlayerConf.supportToolbar {
        didSet { removeAllGesturer() }
    }

    public var supportLodaing: Bool = WDPlayerConf.supportLodaing {
        didSet { }
    }
    
    public var toolType: WDPlayerConf.ToolType = WDPlayerConf.toolType {
        didSet {
            thumView.removeFromSuperview()
            progressTimeLabel.removeFromSuperview()
            if isThumView() {
                suspendIsHidden = false
                addSubview(thumView)
            } else {
                suspendIsHidden = true
                addSubview(progressTimeLabel)
            }
            automaticLayout()
        }
    }

    /**< 暂停 */
    public var isSuspended: Bool = false {
        didSet {
            suspendButton.isHidden = !isSuspended
            if suspendButton.isHidden == false {
                hiddenLoadingView()
            } else {
                if isShowLoading { showLoadingView(afterDelay: 0.25) }
            }
        }
    }
    
    /**< 总时间 */
    public var totalTime: Int = 0 {
        didSet {
            panGestureRecognizer?.isEnabled = true
        }
    }

    /**< 当前时间 */
    public var currentlTime: Int = 0 {
        didSet { }
    }
    
    /**< 删除suspendButton按钮 */
    public var suspendIsHidden: Bool = false {
        didSet {
            if suspendIsHidden {
                suspendButton.removeFromSuperview()
            } else {
                addSubview(suspendButton)
                automaticLayout()
            }
        }
    }
    
    /**< 显示 */
    func showThumView(currentlTime: Int) {
        thumView.isHidden = false
        thumView.currentlTime = currentlTime
        delegate?.currentImage(currentTime: currentlTime, results: { self.thumView.currentlImage = $0 })
    }
    
    /**< 隐藏 */
    func hidenThumView() {
        thumView.isHidden = true
    }
    
    /// 显示菊花
    func showLoadingView(afterDelay: TimeInterval = 0.5) {
        isShowLoading = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_showLoadingView), object: nil)
        perform(#selector(_showLoadingView), with: nil, afterDelay: afterDelay)
    }

    /// 隐藏菊花
    func hiddenLoadingView() {
        guard supportLodaing else { return }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_showLoadingView), object: nil)
        loadingView.hide()
        isShowLoading = false
    }

    @objc fileprivate func _showLoadingView() {
        guard supportLodaing, isSuspended == false else { return }
        loadingView.start()
    }

    public var isFullScreen: Bool = false
    fileprivate weak var delegate: WDPlayerTouchViewProtocol? = nil
    fileprivate var panDirection: PanDirection = .free
    fileprivate var singleGesture: UITapGestureRecognizer? = nil
    fileprivate var doubleGesture: UITapGestureRecognizer? = nil
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer? = nil
    fileprivate var volumeSlider: UISlider? = nil
    fileprivate var horizontalX: CGFloat = 0
    fileprivate var verticalY: CGFloat = 0
    fileprivate var slipInstantaneousTime: Int = 0
    fileprivate var slipInstantaneousEndTime: Int = 0
    fileprivate var isSliding: Bool = false
    fileprivate var isShowLoading: Bool = false
    convenience init(delegate: WDPlayerTouchViewProtocol?) {
        self.init()
        self.delegate = delegate
        self.addGestures()
        self.addSubclassView()
        self.volumeControl()
    }

    @objc fileprivate func singleTap() {
        delegate?.singleTap(touchView: self)
    }

    @objc fileprivate func doubleTap() {
        suspendButton.alpha = 1
        hidenAllControl()
        delegate?.doubleTap(touchView: self)
    }

    @objc fileprivate func suspend() {
        isSuspended = false
        delegate?.suspended(isSuspended: isSuspended)
        delegate?.hiddenBar(hidden: true, isAnimation: true)
    }

    fileprivate func addSubclassView() {
        addSubview(suspendButton)
        if supportLodaing {
            addSubview(loadingView)
        }

        if supportPanGestureRecognizer {
            addSubview(brightness)
            addSubview(volume)
            isThumView() ? addSubview(thumView) : addSubview(progressTimeLabel)
        }
        automaticLayout()
    }

    fileprivate func automaticLayout() {
        let width = loadingView.frame.size.width
        hasSupview(loadingView)?.snp.remakeConstraints { (make) in
            make.width.height.equalTo(width)
            make.center.equalToSuperview()
        }

        hasSupview(suspendButton)?.snp.remakeConstraints { (make) in
            make.width.height.equalTo(52)
            make.center.equalToSuperview()
        }
      
        hasSupview(brightness)?.snp.remakeConstraints { (make) in
            make.width.equalTo(180)
            make.height.equalTo(30)
            make.center.equalToSuperview()
        }

        hasSupview(volume)?.snp.remakeConstraints { (make) in
            make.width.height.equalTo(brightness)
            make.center.equalToSuperview()
        }
        
        hasSupview(thumView)?.snp.remakeConstraints { (make) in
            make.width.equalTo(WDPlayerConf.thumbnailWidth)
            make.height.equalTo(WDPlayerConf.thumbnailWidth * (9 / 16.0) + 30)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(8)
        }
        
        progressTimeLabel.text = "00:00"
        hasSupview(progressTimeLabel)?.snp.remakeConstraints { (make) in
            make.width.equalTo(150)
            make.height.equalTo(30)
            make.centerX.centerY.equalToSuperview()
        }
        
    }
    
    /**< 添加手势 */
    fileprivate func addGestures() {

        /**< 单击双击 doubleTap暂停 singleTap显示工具栏 */
        if supportToolbar, supportDoubleClick {
            let singleGesture = WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(singleTap))
            let doubleGesture = WDPlayerAssistant.addTapGesture(self, taps: 2, touches: 1, selector: #selector(doubleTap))
            singleGesture.require(toFail: doubleGesture)
            self.singleGesture = singleGesture
            self.doubleGesture = doubleGesture
        } else if supportToolbar, supportDoubleClick == false {
            WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(doubleTap))
        } else if supportToolbar == false {
            suspendIsHidden = false
            WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(doubleTap))
        }

        /**< 滑动手势 */
        if supportPanGestureRecognizer {
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(pan:)))
            self.addGestureRecognizer(panGestureRecognizer)
            self.panGestureRecognizer = panGestureRecognizer
            self.panGestureRecognizer?.isEnabled = false
            if let vc = UIViewController.currentVC() {
                vc.navigationController?.interactivePopGestureRecognizer?.require(toFail: panGestureRecognizer)
            }
        }
    }
            
    /**< 音量 */
    fileprivate func volumeControl() {
        guard supportPanGestureRecognizer else { return }
        let volumeView = MPVolumeView(frame: CGRect(x: -20, y: -20, width: 1, height: 1))
        for view in volumeView.subviews {
            if let volumeSlider = view as? UISlider {
                self.volumeSlider = volumeSlider
            }
        }
        insertSubview(volumeView, at: 0)
        clipsToBounds = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(volumeChange(_:)),
            name: Notification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )
        
        /**< 通知 */
        NotificationCenter.default.addObserver(self, selector: #selector(resignActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
        
    @objc func volumeChange(_ notification: NSNotification) {
        guard supportPanGestureRecognizer else { return }
        let userInfo = notification.userInfo!
        if let volumeValue = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? Double {
            hidenAllControl()
            if let explicitVolumeChange = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String {
                if explicitVolumeChange == "ExplicitVolumeChange" || explicitVolumeChange != "RouteChange" {
                    volume.isHidden = false
                }
            }
            volume.progress = Int(volumeValue * 100)
            playerCancelPrevious(selector: #selector(hidenDelay), afterDelay: 2)
        }
    }

    @objc fileprivate func resignActive() {
        guard supportPanGestureRecognizer else { return }
        brightness.progress = Int(UIScreen.main.brightness * 100)
    }

    fileprivate func remoGestureRecognizer(_ tap: UIGestureRecognizer?) {
        guard let tap = tap else { return }
        removeGestureRecognizer(tap)
    }

    fileprivate lazy var loadingView: WDPlayerLoadingView = {
        if let loadingView = WDPlayerLoadingView.share {
            return loadingView
        }
        return WDPlayerLoadingView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
    }()

    fileprivate lazy var suspendButton: UIButton = {
        var suspendButton = UIButton()
        suspendButton.setBackgroundImage(UIImage(named: "new_allPlay_44x44_"), for: .normal)
        suspendButton.isHidden = true
        suspendButton.addTarget(self, action: #selector(suspend), for: .touchUpInside)
        return suspendButton
    }()

    fileprivate lazy var brightness: WDPlayVolumeBrightness = {
        var brightness = WDPlayVolumeBrightness(type: .brightness)
        brightness.progress = Int(UIScreen.main.brightness * 100)
        brightness.isHidden = true
        return brightness
    }()

    fileprivate lazy var volume: WDPlayVolumeBrightness = {
        var volume = WDPlayVolumeBrightness(type: .volume)
        volume.progress = Int(AVAudioSession.sharedInstance().outputVolume * 100)
        volume.isHidden = true
        return volume
    }()
    
    fileprivate lazy var thumView: WDPlayerThumView = {
        var thumView = WDPlayerThumView(delegate: delegate)
        thumView.progressTimeLabel.font = .systemFont(ofSize: 20)
        thumView.isHidden = true
        return thumView
    }()
    
    public lazy var progressTimeLabel: UILabel = {
        var progressTimeLabel = UILabel()
        progressTimeLabel.textAlignment = .center
        progressTimeLabel.font = .systemFont(ofSize: 16)
        progressTimeLabel.textColor = .white
        progressTimeLabel.numberOfLines = 1
        progressTimeLabel.isHidden = true
        progressTimeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        progressTimeLabel.layer.cornerRadius = 5
        progressTimeLabel.layer.masksToBounds = true
        return progressTimeLabel
    }()
    
}

extension WDPlayerViewTouchControl {
    
    /**< 滑动手势 */
    @objc func handleSwipe(pan: UIPanGestureRecognizer) {
      
        /**< 速度 */
        let velocity = pan.velocity(in: pan.view)
        
        /**< 位置 */
        let location = pan.location(in: pan.view)
        
        /**< 开始触摸判断方向 */
        if (pan.state == .began) {
            
            hidenAllControl()
            panDirection = .free
            horizontalX = location.x
            verticalY = location.y
            slipInstantaneousTime = 0
            slipInstantaneousEndTime = 0
            
            if abs(velocity.x) > abs(velocity.y) {
                panDirection = .horizontal
                slipInstantaneousTime = currentlTime
                hasSupview(thumView)?.isHidden = false
                hasSupview(progressTimeLabel)?.isHidden = false
                loadingView.alpha = 0
                suspendButton.alpha = 0
                
            } else if let view = pan.view, location.x <= view.frame.size.width / 2.0 {
                if isSupportVolumeBrightness == false, isFullScreen == false { return }
                panDirection = .verticalLeft
                brightness.isHidden = false
                slipInstantaneousTime = brightness.progress
                
            } else {
                if isSupportVolumeBrightness == false, isFullScreen == false { return }
                panDirection = .verticalRight
                volume.isHidden = false
                slipInstantaneousTime = volume.progress
            }
                     
            delegate?.hiddenBar(hidden: true, isAnimation: false)
            playerCancelPrevious(selector: #selector(hidenDelay), afterDelay: -1)
        }

        if (pan.state == .changed) {
                                    
            /**< 进度 */
            if panDirection == .horizontal {
                hasSupview(thumView)?.isHidden = false
                hasSupview(progressTimeLabel)?.isHidden = false
                
                let displacement = location.x - horizontalX
                let displacementABS = abs(displacement)
                let width = pan.view?.frame.size.width ?? 0
                let amplitude: Int = Int((displacementABS / width) * WDPlayerConf.playerProgressAdjustment)
                
                /**< 快进 */
                if displacement > 0 {

                    slipInstantaneousEndTime = min(slipInstantaneousTime + amplitude, totalTime)
                    progressTimeLabel.text = WDPlayerAssistant.timeTranslate(slipInstantaneousEndTime) + "  /  " + WDPlayerAssistant.timeTranslate(totalTime)
                    thumView.currentlTime = slipInstantaneousEndTime
                    delegate?.currentImage(currentTime: slipInstantaneousEndTime, results: { self.thumView.currentlImage = $0 })
                                       
                    if slipInstantaneousEndTime >= totalTime {
                        slipInstantaneousTime = totalTime
                        horizontalX = location.x
                    }


                } else {

                    slipInstantaneousEndTime = max(slipInstantaneousTime - amplitude, 0)
                    progressTimeLabel.text = WDPlayerAssistant.timeTranslate(slipInstantaneousEndTime) + "  /  " + WDPlayerAssistant.timeTranslate(totalTime)
                    thumView.currentlTime = slipInstantaneousEndTime
                    delegate?.currentImage(currentTime: slipInstantaneousEndTime, results: { self.thumView.currentlImage = $0 })
                                        
                    if slipInstantaneousEndTime <= 0 {
                        slipInstantaneousTime = 0
                        horizontalX = location.x
                    }
                }
            }
            
            func relocation(_ caps: Bool = true) {
                if slipInstantaneousEndTime >= 100, caps == true {
                    slipInstantaneousTime = 100
                    verticalY = location.y
                } else if slipInstantaneousEndTime <= 0, caps == false {
                    slipInstantaneousTime = 0
                    verticalY = location.y
                }
            }
                        
            /**< 亮度 */
            if panDirection == .verticalLeft {
                brightness.isHidden = false
                let displacement = location.y - verticalY
                let displacementABS = abs(displacement)
                let height = pan.view?.frame.size.height ?? 0
                let amplitude: Int = Int((displacementABS / height) * 200)
                if displacement < 0 {

                    slipInstantaneousEndTime = min(slipInstantaneousTime + amplitude, 100)
                    brightness.progress = slipInstantaneousEndTime
                    UIScreen.main.brightness = brightness.progressFloat()
                    relocation()
                    
                } else {
                    
                    slipInstantaneousEndTime = max(slipInstantaneousTime - amplitude, 0)
                    brightness.progress = slipInstantaneousEndTime
                    UIScreen.main.brightness = brightness.progressFloat()
                    relocation(false)
                }
            }
            
            
            /**< 音量 */
            if panDirection == .verticalRight {
                volume.isHidden = false
                let displacement = location.y - verticalY
                let displacementABS = abs(displacement)
                let height = pan.view?.frame.size.height ?? 0
                let amplitude: Int = Int((displacementABS / height) * 200)
                if displacement < 0 {
                    slipInstantaneousEndTime = min(slipInstantaneousTime + amplitude, 100)
                    volume.progress = slipInstantaneousEndTime
                    volumeSlider?.value = Float(volume.progressFloat())
                    relocation()
                    
                } else {
                    slipInstantaneousEndTime = max(slipInstantaneousTime - amplitude, 0)
                    volume.progress = slipInstantaneousEndTime
                    volumeSlider?.value = Float(volume.progressFloat())
                    relocation(false)
                }
            }
            
        }
        
        /**< 滑动结束 */
        if (pan.state == .ended || pan.state == .failed || pan.state == .cancelled) {
            if pan.state == .ended, panDirection == .horizontal {
                delegate?.eventValueChanged(currentlTime: slipInstantaneousEndTime, moving: false)
                thumView.isHidden = true
                progressTimeLabel.isHidden = true
                
                loadingView.alpha = 1
                suspendButton.alpha = 1
                currentlTime = slipInstantaneousEndTime
            }

            if pan.state == .ended, panDirection == .verticalLeft || panDirection == .verticalRight {
                perform(#selector(hidenDelay), with: nil, afterDelay: 2)
            }

            self.panDirection = .free
        }
    }
    
    func hidenAllControl() {
        playerCancelPrevious(selector: #selector(hidenDelay), afterDelay: -1)
        thumView.isHidden = true
        brightness.isHidden = true
        volume.isHidden = true
    }

    @objc func hidenDelay() {
        brightness.isHidden = true
        volume.isHidden = true
    }

    func removeAllGesturer() {
        remoGestureRecognizer(doubleGesture)
        remoGestureRecognizer(singleGesture)
        remoGestureRecognizer(panGestureRecognizer)
        addGestures()
    }
    
    fileprivate func isThumView() -> Bool {
        return (toolType == .tencent)
    }

    fileprivate func hasSupview(_ view: UIView) -> UIView? {
        if (view.superview != nil) {
            return view
        }
        return nil
    }
}
