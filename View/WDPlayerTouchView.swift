//
//  WDPlayerTouchView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/5.
//

import UIKit

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
            panDirection = .free
            horizontalX = location.x
            verticalY = location.y
            slipInstantaneousTime = currentlTime

            if abs(velocity.x) > abs(velocity.y) {
                panDirection = .horizontal
                actionProgress.currentlTime = slipInstantaneousTime
                actionProgress.backgroundAnimation()
                actionProgress.isHidden = false
                suspendButton.alpha = 0
                delegate?.hiddenBar(touchView: self, hidden: false)
                /**< kLogPrint("进度") */

            } else if let view = pan.view, location.x <= view.frame.size.width / 2.0 {
                panDirection = .verticalLeft
                /**< kLogPrint("亮度") */

            } else {
                panDirection = .verticalRight
                /**< kLogPrint("音量") */
            }
        }

        /**< 滑动中 */
        if (pan.state == .changed) {
           
            /**< 进度 */
            if panDirection == .horizontal {
                
                /**< 位移 */
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
            
        }
        
        /**< 滑动结束 */
        if (pan.state == .ended || pan.state == .failed || pan.state == .cancelled) {
            if pan.state == .ended, panDirection == .horizontal {
                delegate?.eventValueChanged(touchView: self, currentlTime: slipInstantaneousEndTime)
                actionProgress.isHidden = true
                suspendButton.alpha = 1
                actionProgress.backgroundAnimation(false)
                delegate?.hiddenBar(touchView: self, hidden: true)
            }

            self.panDirection = .free
        }

       
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
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer? = nil

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

    convenience init(delegate: WDPlayerTouchViewDelegate?) {
        self.init()
        self.delegate = delegate
        self.addGestures()
        self.addLoadingView()
        self.hiddenLoadingView()
    }

    @objc fileprivate func _showLoadingView() {
        loadingView.start()
        loadingView.isHidden = false
    }

    @objc func singleTap() {
        delegate?.singleTap(touchView: self)
    }

    @objc func doubleTap() {
        delegate?.doubleTap(touchView: self)
    }

    @objc func suspend() {
        delegate?.resumePlay(touchView: self)
    }

    fileprivate func addLoadingView() {
        addSubview(actionProgress)
        addSubview(loadingView)
        addSubview(suspendButton)
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
    }
    
    /**< 添加手势 */
    fileprivate func addGestures() {
        
        /**< 单击双击 */
        if WDPlayConf.supportDoubleClick {
            let singleGesture = WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(singleTap))
            let doubleGesture = WDPlayerAssistant.addTapGesture(self, taps: 2, touches: 1, selector: #selector(doubleTap))
            singleGesture.require(toFail: doubleGesture)
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

}


