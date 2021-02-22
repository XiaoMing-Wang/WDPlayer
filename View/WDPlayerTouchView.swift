//
//  WDPlayerTouchView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/5.
//

import UIKit
import MediaPlayer
import AVFoundation

protocol WDPlayerTouchViewDelegate: class {

    /**< 单击 */
    func singleTap(touchView: WDPlayerTouchView)

    /**< 双击 */
    func doubleTap(touchView: WDPlayerTouchView)

    /**< 开始 */
    func resumePlay(touchView: WDPlayerTouchView)

    /**< 进度回调 */
    func eventValueChanged(touchView: WDPlayerTouchView, currentlTime: Int)
    
    /**< 隐藏导航栏 */
    func hiddenBar(touchView: WDPlayerTouchView, hidden: Bool)
}

extension WDPlayerTouchView {

    /// 显示菊花
    func showLoadingView(afterDelay: TimeInterval = 0.5) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_showLoadingView), object: nil)
        perform(#selector(_showLoadingView), with: nil, afterDelay: afterDelay)
    }

    /// 隐藏菊花
    func hiddenLoadingView() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_showLoadingView), object: nil)
        loadingView.hide()
        loadingView.isHidden = true
    }
    
    /// 删除双击
    func deleDoubleClick() {
        remoGestureRecognizer(doubleGesture)
        remoGestureRecognizer(singleGesture)
        remoGestureRecognizer(panGestureRecognizer)
        WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(singleTap))
    }

}

extension WDPlayerTouchView {
    
    /**< 滑动手势 */
    @objc func handleSwipe(pan: UIPanGestureRecognizer) {
      
        /**< 速度 */
        let velocity = pan.velocity(in: pan.view)
        
        /**< 位置 */
        let location = pan.location(in: pan.view)
        
        /**< 开始触摸判断方向 */
        if (pan.state == .began) {
            hidenAllControl()
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hidenDelay), object: nil)
            
            panDirection = .free
            horizontalX = location.x
            verticalY = location.y
            slipInstantaneousTime = 0
            slipInstantaneousEndTime = 0
            
            if abs(velocity.x) > abs(velocity.y) {
                panDirection = .horizontal
                slipInstantaneousTime = currentlTime
                actionProgress.currentlTime = currentlTime
                actionProgress.backgroundAnimation()
                actionProgress.isHidden = false
                suspendButton.alpha = 0
                delegate?.hiddenBar(touchView: self, hidden: false)
                
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
        }

        if (pan.state == .changed) {
                       
            /**< 进度 */
            if panDirection == .horizontal {
                actionProgress.isHidden = false
                let displacement = location.x - horizontalX
                let displacementABS = abs(displacement)
                let width = pan.view?.frame.size.width ?? 0
                let amplitude: Int = Int((displacementABS / width) * WDPlayConf.playerProgressAdjustment)
                
                /**< 快进 */
                if displacement > 0 {
                    slipInstantaneousEndTime = min(slipInstantaneousTime + amplitude, totalTime)
                    actionProgress.currentlTime = slipInstantaneousEndTime
                    if slipInstantaneousEndTime >= totalTime {
                        slipInstantaneousTime = totalTime
                        horizontalX = location.x
                    }
                } else {
                    slipInstantaneousEndTime = max(slipInstantaneousTime - amplitude, 0)
                    actionProgress.currentlTime = slipInstantaneousEndTime
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
                delegate?.eventValueChanged(touchView: self, currentlTime: slipInstantaneousEndTime)
                actionProgress.isHidden = true
                suspendButton.alpha = 1
                actionProgress.backgroundAnimation(false)
                delegate?.hiddenBar(touchView: self, hidden: true)
                currentlTime = slipInstantaneousEndTime
            }

            if pan.state == .ended, panDirection == .verticalLeft || panDirection == .verticalRight {
                perform(#selector(hidenDelay), with: nil, afterDelay: 2)
            }

            self.panDirection = .free
        }
    }
    
    func hidenAllControl() {
        actionProgress.isHidden = true
        brightness.isHidden = true
        volume.isHidden = true
    }

    @objc func hidenDelay() {
        brightness.isHidden = true
        volume.isHidden = true
    }

}

class WDPlayerTouchView: UIView {

    enum PanDirection {
        case free
        case horizontal //水平
        case verticalLeft //竖直左
        case verticalRight //竖直右
    }

    fileprivate weak var delegate: WDPlayerTouchViewDelegate? = nil
    fileprivate var panDirection: PanDirection = .free
    fileprivate var singleGesture: UITapGestureRecognizer? = nil
    fileprivate var doubleGesture: UITapGestureRecognizer? = nil
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer? = nil
    fileprivate var volumeSlider: UISlider? = nil

    /**< 横纵向初始位置 */
    fileprivate var horizontalX: CGFloat = 0
    fileprivate var verticalY: CGFloat = 0
    fileprivate var slipInstantaneousTime: Int = 0
    fileprivate var slipInstantaneousEndTime: Int = 0
    fileprivate var isSliding: Bool = false

    public var isSuspended: Bool = false {
        didSet {
            suspendButton.isHidden = !isSuspended
            if suspendButton.isHidden == false {
                hiddenLoadingView()
            }
        }
    }
    
    /**< 总时间 */
    public var totalTime: Int = 0 {
        didSet {
            actionProgress.totalTime = totalTime
            panGestureRecognizer?.isEnabled = true
        }
    }

    /**< 当前时间 */
    public var currentlTime: Int = 0 {
        didSet { }
    }

    /**< 是否支持亮度音量调节 */
    var isSupportVolumeBrightness: Bool = true
    var isFullScreen: Bool = false
    
    convenience init(delegate: WDPlayerTouchViewDelegate?) {
        self.init()
        self.delegate = delegate
        self.addGestures()
        self.addLoadingView()
        self.hiddenLoadingView()
        self.volumeControl()
    }

    @objc fileprivate func _showLoadingView() {
        loadingView.start()
        loadingView.isHidden = false
    }

    @objc func singleTap() {
        delegate?.singleTap(touchView: self)
    }

    @objc func doubleTap() {
        suspendButton.alpha = 1
        delegate?.doubleTap(touchView: self)
    }

    @objc func suspend() {
        delegate?.resumePlay(touchView: self)
    }

    fileprivate func addLoadingView() {
        addSubview(actionProgress)
        addSubview(loadingView)
        addSubview(suspendButton)
        addSubview(brightness)
        addSubview(volume)
        automaticLayout()
    }

    fileprivate func automaticLayout() {
        let width = loadingView.frame.size.width
        loadingView.snp.makeConstraints { (make) in
            make.width.height.equalTo(width)
            make.center.equalToSuperview()
        }

        suspendButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(52)
            make.center.equalToSuperview()
        }

        actionProgress.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        brightness.snp.makeConstraints { (make) in
            make.width.equalTo(180)
            make.height.equalTo(30)
            make.center.equalToSuperview()
        }

        volume.snp.makeConstraints { (make) in
            make.width.height.equalTo(brightness)
            make.center.equalToSuperview()
        }
    }
    
    /**< 添加手势 */
    fileprivate func addGestures() {
        
        /**< 单击双击 */
        if WDPlayConf.supportDoubleClick {
            let singleGesture = WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(singleTap))
            let doubleGesture = WDPlayerAssistant.addTapGesture(self, taps: 2, touches: 1, selector: #selector(doubleTap))
            singleGesture.require(toFail: doubleGesture)
            self.singleGesture = singleGesture
            self.doubleGesture = doubleGesture
        } else {
            WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(doubleTap))
        }

        /**< 滑动手势 */
        if WDPlayConf.supportPanGestureRecognizer {
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(pan:)))
            self.addGestureRecognizer(panGestureRecognizer)
            self.panGestureRecognizer = panGestureRecognizer
            self.panGestureRecognizer?.isEnabled = false
        }
    }
            
    /**< 音量 */
    fileprivate func volumeControl() {
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
        let userInfo = notification.userInfo!
        if let volumeValue = userInfo["AVSystemController_AudioVolumeNotificationParameter"] as? Double {
            hidenAllControl()
            if let explicitVolumeChange = userInfo["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as? String {
                if explicitVolumeChange == "ExplicitVolumeChange" || explicitVolumeChange != "RouteChange" {
                    volume.isHidden = false
                }
            }
            volume.progress = Int(volumeValue * 100)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hidenDelay), object: nil)
            perform(#selector(hidenDelay), with: nil, afterDelay: 2)
        }
    }

    @objc func resignActive() {
        brightness.progress = Int(UIScreen.main.brightness * 100)
    }

    func remoGestureRecognizer(_ tap: UIGestureRecognizer?) {
        guard let tap = tap else { return }
        removeGestureRecognizer(tap)
    }

    fileprivate lazy var loadingView: WDPLayLoadingView = {
        var loadingView = WDPLayLoadingView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        return loadingView
    }()

    /**< 暂停图标 */
    fileprivate lazy var suspendButton: UIButton = {
        var suspendButton = UIButton()
        suspendButton.setImage(UIImage(named: "new_allPlay_44x44_"), for: .normal)
        suspendButton.isHidden = true
        suspendButton.addTarget(self, action: #selector(suspend), for: .touchUpInside)
        return suspendButton
    }()

    /**< 进度调节 */
    fileprivate lazy var actionProgress: WDPlayTouchActionProgress = {
        var actionProgress = WDPlayTouchActionProgress(totalTime: 0)
        actionProgress.isHidden = true
        return actionProgress
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
}


