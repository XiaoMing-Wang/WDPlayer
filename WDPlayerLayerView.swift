//
//  WDPlayerLayerView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit
import SnapKit
import AVFoundation

protocol WDPlayerLayerViewDelegate: class {

    /**< 暂停 */
    func suspended(layerView: WDPlayerLayerView)

    /**< 继续播放 */
    func play(layerView: WDPlayerLayerView)

    /**< 进度 */
    func eventValueChanged(currentlTime: Int)
}

/**< 播放界面 */
class WDPlayerContentView: UIImageView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer? {
        return layer as? AVPlayerLayer
    }

    func setPlayer(_ avplayer: AVPlayer?) {
        playerLayer?.player = avplayer
    }
}

extension WDPlayerLayerView {

    /// 设置拉伸类型
    /// - Parameter contentMode: contentMode
    func setContentMode(_ contentMode: WDPlayConf.ContentMode) {
        _setContentMode(contentMode)
    }

    /// 设置总时间
    /// - Parameter duration: duration
    func setTotalDuration(_ duration: Int) {
        toolbarView.totalTime = duration
        touchView.totalTime = duration
    }

    /// 设置当前时间
    /// - Parameter duration: duration
    func setCurrentDuration(_ duration: Int) {
        toolbarView.currentlTime = duration
        touchView.currentlTime = duration
    }
    
    /// 设置缓冲时间
    /// - Parameter duration: duration
    func setBufferDuration(_ duration: Int) {
        toolbarView.bufferTime = duration
    }

    /// 显示隐藏菊花
    /// - Parameter display: display
    func disPlayLoadingView(_ display: Bool = true, afterDelay: TimeInterval = 0.65) {
        guard WDPlayConf.supportLodaing else { return }
        display ? touchView.showLoadingView(afterDelay: afterDelay) : touchView.hiddenLoadingView()
    }

}

fileprivate extension WDPlayerLayerView {

    func _setContentMode(_ contentMode: WDPlayConf.ContentMode) {
        contentModeType = contentMode

        /**< 有黑边的那种 */
        if contentMode == .blackBorder {
            contentsView.contentMode = .scaleAspectFit
            contentsView.playerLayer?.videoGravity = .resizeAspect

            /**< 填充满变形 */
        } else if contentMode == .fullScreenVariant {
            contentsView.contentMode = .scaleToFill
            contentsView.playerLayer?.videoGravity = .resize

            /**< 填充满不变形 */
        } else if contentMode == .fullScreenTailor {
            contentsView.contentMode = .scaleAspectFill
            contentsView.playerLayer?.videoGravity = .resizeAspectFill
        }
    }

    /**< 设置layer */
    func setPlaybackLayer(player: AVPlayer?) {
        contentsView.setPlayer(player)
    }

    /**< 暂停 */
    @objc func suspend(transform: Bool = true) {
        guard isAnimation == false else { return }
        if transform { isSuspended = !isSuspended }
        isSuspended ? delegate?.suspended(layerView: self) : delegate?.play(layerView: self)
        touchView.isSuspended = isSuspended
        toolbarView.isSuspended = isSuspended
        cancelHideToolbar()
    }
    
    /**< 处理工具栏 */
    @objc func handleBar() {
        if isShowToolBar {
            hiddenToolBar()
        } else {
            showToolBar()
        }
    }

    /**< 显示导航栏 */
    @objc func showToolBar() {
        cancelHideToolbar()
        
        if WDPlayConf.showTopBar == true {
            topBar.snp.updateConstraints { (make) in
                make.top.equalTo(0)
            }
        }

        if WDPlayConf.showToolBar == true {
            let bottom = isFullScreen ? -WDPlayConf.safeBottom() : 0
            toolbarView.snp.updateConstraints { (make) in
                make.bottom.equalTo(bottom)
            }
        }

        isShowToolBar = true
        layoutIfNeededAnimate(duration: 0.25)
    }

    /**< 隐藏导航栏 */
    @objc func hiddenToolBar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
        
        if WDPlayConf.showTopBar == true {
            topBar.snp.updateConstraints { (make) in
                make.top.equalTo(-topBarDistance)
            }
        }

        if WDPlayConf.showToolBar == true {
            toolbarView.snp.updateConstraints { (make) in
                make.bottom.equalTo(bottomBarDistance)
            }
        }
       
        isShowToolBar = false
        layoutIfNeededAnimate(duration: 0.25)
    }

}

/**< 工具栏回调  触摸view回调 */
extension WDPlayerLayerView: WPPlayerViewBarDelegate, WDPlayerTouchViewDelegate {

    /**< 单击 */
    func singleTap(touchView: WDPlayerTouchView) {
        if WDPlayConf.supportDoubleClick {
            handleBar()
        } else {
            suspend()
        }
    }

    /**< 双击 */
    func doubleTap(touchView: WDPlayerTouchView) {
        suspend()
    }

    /**< 恢复播放 */
    func resumePlay(touchView: WDPlayerTouchView) {
        isSuspended = true
        suspend()
    }

    /**< 滑块滑动 */
    func eventValueChanged(currentlTime: Int) {
        touchView.currentlTime = currentlTime
        delegate?.eventValueChanged(currentlTime: currentlTime)
    }

    /**< 屏幕滑动 */
    func eventValueChanged(touchView: WDPlayerTouchView, currentlTime: Int) {
        toolbarView.currentlTime = currentlTime
        delegate?.eventValueChanged(currentlTime: currentlTime)
    }
    
    /**< 隐藏导航栏 */
    func hiddenBar(touchView: WDPlayerTouchView, hidden: Bool) {
        if hidden == false {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
        } else {
            perform(#selector(hiddenToolBar), with: nil, afterDelay: 3)
        }
    }

    /**< 取消消失工具栏 */
    func cancelHideToolbar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
        perform(#selector(hiddenToolBar), with: nil, afterDelay: 3)
    }

    /**< 暂停播放 */
    func suspended(isSuspended: Bool) {
        self.isSuspended = isSuspended
        self.suspend(transform: false)
    }

    /**< 返回按钮点击 */
    func backClick() {
        if isFullScreen {
            thum()
        }
    }

    /// 点击全屏按钮
    func fullClick(isFull: Bool) {
        isFullScreen = isFull
        isFullScreen ? full() : thum()
    }

    /**< 放大 */
    fileprivate func full() {
        cancelHideToolbar()
        isFullScreen = true
        topBar.isFullScreen = true
        toolbarView.isFullScreen = true
        originalSizePlay = frame.size
        originalCenterYPlay = WDPlayerAssistant.locationWindow_play(self).origin.y + (originalSizePlay.height / 2)

        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        let fullViewController = WDPlayerFullViewController()
        fullViewController.modalPresentationStyle = .fullScreen
        if let imaView = WDPlayerAssistant.makeImageWindow_play(rootViewController?.view) {
            fullConstraint()
            rootViewController?.view.addSubview(imaView)
            rootViewController?.present(fullViewController, animated: true, completion: {
                imaView.removeFromSuperview()
            })
        }
        self.fullViewController = fullViewController
        
    }

    /**< 还原 */
    fileprivate func thum() {
        cancelHideToolbar()
        fullConstraint(full: false)
        fullViewController?.dismiss(animated: true, completion: {
            self.fullViewController = nil
            self.originalSizePlay = .zero
            self.originalCenterYPlay = 0
            self.isFullScreen = false
            self.topBar.isFullScreen = false
            self.toolbarView.isFullScreen = false
        })
    }
}

class WDPlayerLayerView: UIView {

    fileprivate weak var delegate: WDPlayerLayerViewDelegate? = nil
    
    /**< 是否处于暂停 */
    fileprivate var isSuspended: Bool = false
    fileprivate var isAnimation: Bool = false
    
    /**< 是否显示状态栏 */
    fileprivate var isShowToolBar: Bool = true
    
    fileprivate var topBarDistance: CGFloat = 0
    fileprivate var bottomBarDistance: CGFloat = 0
        
    /**< 手是否处于横屏 */
    fileprivate var isFullScreen: Bool = false
    fileprivate var contentModeType: WDPlayConf.ContentMode? = nil
    fileprivate weak var fullViewController: WDPlayerFullViewController? = nil

    convenience init(player: AVPlayer?, delegate: WDPlayerLayerViewDelegate?) {
        self.init(frame: .zero)
        self.delegate = delegate
        initializationInterface()
        setPlaybackLayer(player: player)
    }

    fileprivate func initializationInterface() {
        tag = WDPlayConf.playerLayerTag
        backgroundColor = .black
        clipsToBounds = true

        addSubview(contentsView)
        addSubview(touchView)
        WDPlayConf.showTopBar ? addSubview(topBar) : ()
        WDPlayConf.showToolBar ? addSubview(toolbarView) : ()

        automaticLayout()
        cancelHideToolbar()
        setContentMode(.blackBorder)
    }

    fileprivate func automaticLayout() {
        contentsView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        touchView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(0)
        }

        if WDPlayConf.showTopBar == true {
            topBar.snp.makeConstraints { (make) in
                make.left.right.top.equalTo(0)
                make.height.equalTo(WDPlayConf.toolBarHeight)
            }
        }

        if WDPlayConf.showToolBar  == true {
            toolbarView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalTo(0)
                make.height.equalTo(WDPlayConf.toolBarHeight)
            }
        }
        
        topBarDistance = WDPlayConf.toolBarHeight
        bottomBarDistance = WDPlayConf.toolBarHeight
    }

    /**< 更新约束 */
    fileprivate func fullConstraint(full: Bool = true) {
        
        /**< 顶部导航栏 */
        if WDPlayConf.showTopBar == true {
            topBarDistance = WDPlayConf.toolBarHeight + (full ? 20 : 0)
            
            topBar.fullConstraint(full: full)
            topBar.snp.updateConstraints { (make) in
                make.height.equalTo(topBarDistance)
            }
        }

        /**< 底部导航栏 */
        if WDPlayConf.showToolBar == true {
            let height: CGFloat = WDPlayConf.toolBarHeight + (full ? 20 : 0)
            let safeBottom: CGFloat = WDPlayConf.safeBottom()
            bottomBarDistance = height + (full ? safeBottom : 0)
            
            toolbarView.fullConstraint(full: full)
            toolbarView.snp.updateConstraints { (make) in
                make.height.equalTo(height)
                make.bottom.equalTo((full ? -safeBottom : 0))
            }
        }

        layoutIfNeededAnimate()
    }
    
    /**< 动画转换 */
    func layoutIfNeededAnimate(duration: TimeInterval = WDPlayConf.playerAnimationDuration) {
        UIView.animate(withDuration: duration) {
            self.layoutIfNeeded()
        }
    }

    /**< 播放界面 */
    fileprivate lazy var contentsView: WDPlayerContentView = {
        var contentsView = WDPlayerContentView()
        return contentsView
    }()

    /**< 顶部工具栏 */
    fileprivate lazy var topBar: WPPlayerViewTopBar = {
        var topBar = WPPlayerViewTopBar(titles: "", delegate: self)
        return topBar
    }()

    /**< 中间的触摸view */
    fileprivate lazy var touchView: WDPlayerTouchView = {
        var touchView = WDPlayerTouchView(delegate: self)
        return touchView
    }()

    /**< 底部工具栏 */
    fileprivate lazy var toolbarView: WPPlayerViewToolBar = {
        var toolbarView = WPPlayerViewToolBar(totalTime: 0, delegate: self)
        return toolbarView
    }()

}
