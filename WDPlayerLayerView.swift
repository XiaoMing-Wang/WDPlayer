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
        playerLayer?.player = nil
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
    func disPlayLoadingView(_ display: Bool = true, afterDelay: TimeInterval = 0.30) {
        guard WDPlayConf.supportLodaing else { return }
        display ? touchView.showLoadingView(afterDelay: afterDelay) : touchView.hiddenLoadingView()
    }

    /// 设置layer
    /// - Parameter player: player
    func setPlaybackLayer(player: AVPlayer?) {
        contentsView.setPlayer(player)
    }

    /// 设置封面(网络或者视频URL)
    /// - Parameter coverUrl: coverUrl
    func setCoverUrl(coverUrl: String?, local: Bool = false) {
        WDPlayerAssistant.setImage(imageView: contentsView, forkey: coverUrl, local: local)
    }

    /// 设置封面(截取第一帧率)
    /// - Parameter forkey: 视频的URL地址
    func setFirstImage(_ image: UIImage?, forkey: String?) {
        DispatchQueue.main.async {
            if let image = image, let forkey = forkey {
                self.contentsView.image = image
                self.isSetFirstImage = true
                WDPlayerAssistant.cacheImage(image: image, forkey: forkey)
            }
        }
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

        if WDPlayConf.showTopBar == true, topBar.superview != nil {
            topBar.snp.updateConstraints { (make) in
                make.top.equalTo(0)
            }
        }

        if WDPlayConf.showToolBar == true, topBar.superview != nil {
            toolbarView.snp.updateConstraints { (make) in
                make.bottom.equalTo(0)
            }
        }

        isShowToolBar = true
        layoutIfNeededAnimate(duration: 0.25)
    }

    /**< 隐藏导航栏 */
    @objc func hiddenToolBar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
        
        if WDPlayConf.showTopBar == true, topBar.superview != nil {
            topBar.snp.updateConstraints { (make) in
                make.top.equalTo(-topBarDistance)
            }
        }

        if WDPlayConf.showToolBar == true, toolbarView.superview != nil {
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
        if WDPlayConf.supportDoubleClick, isSupportToolBar == true {
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

    /**< 重置 */
    func reset() {
        toolbarView.reset()
        contentsView.image = nil
        isSetFirstImage = false
    }

    /**< 放大 */
    fileprivate func full() {
        
        cancelHideToolbar()
        isFullScreen = true
        topBar.isFullScreen = true
        touchView.isFullScreen = true
        toolbarView.isFullScreen = true
        originalSizePlay = frame.size
        originalCenterYPlay = WDPlayerAssistant.locationWindow_play(self).origin.y + (originalSizePlay.height / 2)
             
        tag = WDPlayConf.playerLayerTag
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
            self.touchView.isFullScreen = false
            self.toolbarView.isFullScreen = false
            self.tag = 0
        })
    }
}

class WDPlayerLayerView: UIView {

    weak var delegate: WDPlayerLayerViewDelegate? = nil
    
    /**< 是否显示工具栏 */
    var isSupportToolBar: Bool = true {
        didSet {
            if isSupportToolBar == false {
                topBar.removeFromSuperview()
                toolbarView.removeFromSuperview()
                touchView.deleDoubleClick()
            }
        }
    }
    
    /**< 是否支持亮度音量调节 (只能关闭竖屏) */
    var isSupportVolumeBrightness: Bool = true {
        didSet {
            touchView.isSupportVolumeBrightness = isSupportVolumeBrightness
        }
    }
    
    /**< 是否支持横屏 */
    var isSupportFullScreen: Bool = true {
        didSet {
            toolbarView.isSupportFullScreen = isSupportFullScreen
        }
    }
    
    /**< 直接显示菊花 加载前就显示出来 */
    var isDirectDisplayLoading: Bool = false {
        didSet {
            disPlayLoadingView(true)
        }
    }
    
    /**< 第一帧图片 */
    fileprivate(set) var isSetFirstImage: Bool = false

    /**< 是否处于暂停 */
    fileprivate var isSuspended: Bool = false
    fileprivate var isAnimation: Bool = false
    fileprivate var isShowToolBar: Bool = true
    fileprivate var topBarDistance: CGFloat = 0
    fileprivate var bottomBarDistance: CGFloat = 0
    fileprivate var isFullScreen: Bool = false
    fileprivate var isLayoutSubviews: Bool = false
    fileprivate var contentModeType: WDPlayConf.ContentMode? = nil
    fileprivate weak var fullViewController: WDPlayerFullViewController? = nil

    convenience init() {
        self.init(frame: .zero)
        initializationInterface()
    }
    
    fileprivate func initializationInterface() {
        backgroundColor = .black
        clipsToBounds = true
        isDirectDisplayLoading = true
        tag = 0

        addSubview(contentsView)
        addSubview(touchView)
        if WDPlayConf.showTopBar { addSubview(topBar) }
        if WDPlayConf.showToolBar { addSubview(toolbarView) }
        automaticLayout()
        cancelHideToolbar()
        setContentMode(.blackBorder)
    }

    fileprivate func automaticLayout() {
        contentsView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        touchView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        if WDPlayConf.showTopBar == true {
            if topBar.superview == nil { return }
            topBar.snp.makeConstraints { (make) in
                make.left.right.top.equalTo(0)
                make.height.equalTo(WDPlayConf.toolBarHeight)
            }
        }

        if WDPlayConf.showToolBar  == true {
            if toolbarView.superview == nil { return }
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
        let margin = (full ? 55 : 0)
        if WDPlayConf.showTopBar == true, topBar.superview != nil {
            topBarDistance = WDPlayConf.toolBarHeight + (full ? 25 : 0)
            topBar.fullConstraint(full: full)
            topBar.snp.updateConstraints { (make) in
                make.left.equalTo(margin)
                make.right.equalTo(-margin)
                make.height.equalTo(topBarDistance)
            }
        }
        
        /**< 底部导航栏 */
        if WDPlayConf.showToolBar == true, toolbarView.superview != nil {
            bottomBarDistance = WDPlayConf.toolBarHeight + (full ? (27) : 0)
            toolbarView.fullConstraint(full: full)
            toolbarView.snp.updateConstraints { (make) in
                make.left.equalTo(margin)
                make.right.equalTo(-margin)
                make.height.equalTo(bottomBarDistance)
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
    
    /**< 自动布局设置frame */
    override func layoutSubviews() {
        super.layoutSubviews()
        if let bounds = superview?.bounds, frame.size == .zero, frame.origin == .zero, isLayoutSubviews == false {
            frame = CGRect(x: -1, y: -1, width: 1, height: 1)
            frame = bounds
            isLayoutSubviews = true
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
