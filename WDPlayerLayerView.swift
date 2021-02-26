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

class WDPlayerLayerView: UIView {

    weak var delegate: WDPlayerLayerViewDelegate? = nil
  
    /**< 是否显示工具栏 */
    var isSupportToolBar: Bool = WDPlayerConf.supportToolbar {
        didSet {
            if isSupportToolBar == false {
                topBar.removeFromSuperview()
                toolbarView.removeFromSuperview()
                touchView.supportDoubleClick = false
            } else {
                addSubview(topBar)
                addSubview(toolbarView)
                topBarDistance = WDPlayerConf.toolBarHeight
                bottomBarDistance = WDPlayerConf.toolBarHeight
                touchView.supportDoubleClick = true
            }
            automaticLayout()
        }
    }
        
    /**< 是否支持亮度音量调节 (只竖屏关闭) */
    var isSupportVolumeBrightness: Bool = false {
        didSet {
            touchView.isSupportVolumeBrightness = isSupportVolumeBrightness
        }
    }
    
    /**< 是否支持横屏 */
    var isSupportFullScreen: Bool = true {
        didSet {
            if hasSupview(toolbarView) {
                toolbarView.isSupportFullScreen = isSupportFullScreen
            }
        }
    }
    
    /**< 直接显示菊花 加载前就显示出来 */
    var isDirectDisplayLoading: Bool = false {
        didSet { disPlayLoadingView(true)  }
    }
    
    /**< 滑动手势 */
    public var supportPanGestureRecognizer: Bool = WDPlayerConf.supportPanGestureRecognizer {
        didSet {
            if hasSupview(touchView) {
                touchView.supportPanGestureRecognizer = supportPanGestureRecognizer
            }
        }
    }

    /**< 卡顿显示菊花 */
    public var supportLodaing: Bool = WDPlayerConf.supportLodaing {
        didSet {
            if hasSupview(touchView) {
                touchView.supportLodaing = supportLodaing
            }
        }
    }
    
    /**< 暂停 */
    public var isSuspended: Bool = false {
        didSet {
            if hasSupview(touchView) { touchView.isSuspended = isSuspended }
            /**< if hasSupview(youTbBar) { youTbBar.isSuspended = isSuspended } */
        }
    }
    
    /**< 工具栏模式 */
    public var toolType: WDPlayerConf.ToolType = WDPlayerConf.toolType {
        didSet {
            
        }
    }
        
    /// 设置ContentView
    /// - Parameter contentView: contentView
    func setContentView(_ contentView: UIView?) {
        guard let contentView = contentView else { return }
        self.content = contentView
        for subview in contentView.subviews {
            if subview is WDPlayerLayerView {
                subview.removeFromSuperview()
                break
            }
        }

        contentView.isUserInteractionEnabled = true
        do { contentView.insertSubview(self, at: 0) }
    }

    /// 设置拉伸类型
    /// - Parameter contentMode: contentMode
    func setContentMode(_ contentMode: WDPlayerConf.ContentMode) {
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

    /// 返回按钮回调
    /// - Parameter backClosure: backClosure
    func setBackClosure(backClosure: (() -> Void)?) {
        self.backClosure = backClosure
    }
    
    /// 设置总时间
    /// - Parameter duration: duration
    func setTotalDuration(_ duration: Int) {
        totalTime = duration
        if hasSupview(touchView) { touchView.totalTime = duration }
        if hasSupview(toolbarView) { toolbarView.totalTime = duration }
        if hasSupview(youTbBar) { youTbBar?.totalTime = duration }
    }

    /// 设置当前时间
    /// - Parameter duration: duration
    func setCurrentDuration(_ duration: Int) {
        currentlTime = duration
        if hasSupview(touchView) { touchView.currentlTime = duration }
        if hasSupview(toolbarView) { toolbarView.currentlTime = duration }
        if hasSupview(youTbBar) { youTbBar?.currentlTime = duration }
    }

    /// 设置缓冲时间
    /// - Parameter duration: duration
    func setBufferDuration(_ duration: Int) {
        if hasSupview(toolbarView) { toolbarView.bufferTime = duration }
        if hasSupview(youTbBar) { youTbBar?.bufferTime = duration }
    }

    /// 显示隐藏菊花
    /// - Parameter display: display
    func disPlayLoadingView(_ display: Bool = true, afterDelay: TimeInterval = 0.30) {
        guard WDPlayerConf.supportLodaing else { return }
        if hasSupview(touchView) {
            display ? touchView.showLoadingView(afterDelay: afterDelay) : touchView.hiddenLoadingView()
        }
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
    
    /// 重置
    func reset() {
        toolbarView.reset()
        contentsView.image = nil
        isSetFirstImage = false
        touchView.hiddenLoadingView()
    }
    
    
    //MARK:私有
    fileprivate(set) var isSetFirstImage: Bool = false
    fileprivate var totalTime: Int = 0
    fileprivate var currentlTime: Int = 0
    fileprivate var isAnimation: Bool = false
    fileprivate var isShowToolBar: Bool = true
    fileprivate var topBarDistance: CGFloat = 0
    fileprivate var bottomBarDistance: CGFloat = 0
    fileprivate var isFullScreen: Bool = false
    fileprivate var isLayoutSubviews: Bool = false
    fileprivate var contentModeType: WDPlayerConf.ContentMode? = nil
    fileprivate var backClosure: (() -> Void)? = nil
    fileprivate weak var content: UIView? = nil
    fileprivate weak var fullViewController: WDPlayerFullViewController? = nil

    convenience init() {
        self.init(frame: .zero)
        initializationInterface()
    }
    
    fileprivate func initializationInterface() {
        backgroundColor = .black
        clipsToBounds = (toolType == .tencent)
        isDirectDisplayLoading = true
        isSupportVolumeBrightness = false
        tag = 0

        addSubview(contentsView)
        addSubview(touchView)
        if toolType == .tencent, isSupportToolBar {
            addSubview(topBar)
            addSubview(toolbarView)
        } else if toolType == .youtube, isSupportToolBar, let youTbBar = youTbBar {
            insertSubview(youTbBar, aboveSubview: touchView)
            youTbBar.isHidden = true
            isShowToolBar = false
        }
        
        automaticLayout()
        cancelHideToolbar()
        setContentMode(.blackBorder)
    }

    fileprivate func automaticLayout() {
        contentsView.snp.remakeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        touchView.snp.remakeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        hasSupview(youTbBar)?.snp.remakeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        hasSupview(topBar)?.snp.remakeConstraints { (make) in
            make.left.right.top.equalTo(0)
            make.height.equalTo(WDPlayerConf.toolBarHeight)
        }
        
        hasSupview(toolbarView)?.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalTo(0)
            make.height.equalTo(WDPlayerConf.toolBarHeight)
        }
                                        
        topBarDistance = WDPlayerConf.toolBarHeight
        bottomBarDistance = WDPlayerConf.toolBarHeight
    }

    /**< 更新约束 */
    fileprivate func fullConstraint(full: Bool = true) {
        
        /**< 顶部导航栏 */
        if hasSupview(topBar) {
            topBarDistance = WDPlayerConf.toolBarHeight + (full ? 25 : 0)
            topBar.fullConstraint(full: full)
            topBar.snp.updateConstraints { (make) in
                make.height.equalTo(topBarDistance)
            }
        }

        /**< 底部导航栏 */
        if hasSupview(toolbarView) {
            bottomBarDistance = WDPlayerConf.toolBarHeight + (full ? (27) : 0)
            toolbarView.fullConstraint(full: full)
            toolbarView.snp.updateConstraints { (make) in
                make.height.equalTo(bottomBarDistance)
            }
        }

        if hasSupview(youTbBar) {
            youTbBar?.fullConstraint(full: full)
        }
        
        layoutIfNeededAnimate()
    }
    
    /**< 动画转换 */
    fileprivate func layoutIfNeededAnimate(duration: TimeInterval = WDPlayerConf.playerAnimationDuration) {
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

    /**< 工具栏 */
    fileprivate lazy var youTbBar: WDPlayerViewYouTbBar? = {
        guard toolType == .youtube else { return nil }
        var youTbBar = WDPlayerViewYouTbBar(content: self, delegate: self)
        return youTbBar
    }()
    
}

/**< 工具栏回调  触摸view回调 */
extension WDPlayerLayerView: WPPlayerViewBarProtocol, WDPlayerTouchViewDelegate {

    /**< 单击 */
    func singleTap(touchView: WDPlayerTouchView) {
        handleBar()
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
        self.currentlTime = currentlTime
        if hasSupview(touchView) { touchView.currentlTime = currentlTime }
        delegate?.eventValueChanged(currentlTime: currentlTime)
    }

    /**< 屏幕滑动 */
    func eventValueChanged(touchView: WDPlayerTouchView, currentlTime: Int) {
        self.currentlTime = currentlTime
        if hasSupview(toolbarView) { toolbarView.currentlTime = currentlTime }
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
        if hasSupview(topBar) || hasSupview(toolbarView) /* || hasSupview(youTbBar)  */{
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
            perform(#selector(hiddenToolBar), with: nil, afterDelay: 3)
        }
    }
    
    /**< 隐藏导航栏 */
    func hideToolbar() {
        hiddenToolBar()
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
        } else {
            backClosure?()
        }
    }

    /**< 点击全屏按钮 */
    func fullClick(isFull: Bool) {
        isFullScreen = isFull
        isFullScreen ? full() : thum()
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
                     
        tag = WDPlayerConf.playerLayerTag
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

    /**< 暂停 */
    @objc fileprivate func suspend(transform: Bool = true) {
        guard isAnimation == false else { return }
        if transform { isSuspended = !isSuspended }
        isSuspended ? delegate?.suspended(layerView: self) : delegate?.play(layerView: self)
        touchView.isSuspended = isSuspended
        toolbarView.isSuspended = isSuspended
        cancelHideToolbar()
    }
    
    /**< 处理工具栏 */
    @objc fileprivate func handleBar() {
        if isShowToolBar {
            hiddenToolBar()
        } else {
            showToolBar()
        }
    }

    /**< 显示导航栏 */
    @objc fileprivate func showToolBar() {
        cancelHideToolbar()
        if toolType == .tencent {
            
            if hasSupview(topBar) {
                topBar.snp.updateConstraints { (make) in
                    make.top.equalTo(0)
                }
            }

            if hasSupview(toolbarView) {
                toolbarView.snp.updateConstraints { (make) in
                    make.bottom.equalTo(0)
                }
            }
            
            layoutIfNeededAnimate(duration: 0.25)
                        
        } else {
                 
            youTbBar?.alpha = 0
            youTbBar?.isHidden = false
            UIView.animate(withDuration: 0.25) {
                self.youTbBar?.alpha = 1
                self.touchView.suspendAlpha = 0
            }
        }
        
        isShowToolBar = true
    }

    /**< 隐藏导航栏 */
    @objc fileprivate func hiddenToolBar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
        if toolType == .tencent {
            
            if hasSupview(topBar)  {
                topBar.snp.updateConstraints { (make) in
                    make.top.equalTo(-topBarDistance)
                }
            }

            if hasSupview(toolbarView) {
                toolbarView.snp.updateConstraints { (make) in
                    make.bottom.equalTo(bottomBarDistance)
                }
            }

            layoutIfNeededAnimate(duration: 0.25)
                    
        } else {
            
            UIView.animate(withDuration: 0.25) {
                self.youTbBar?.alpha = 0
                self.touchView.suspendAlpha = 1
            } completion: { _ in
                self.youTbBar?.alpha = 1
                self.youTbBar?.isHidden = true
            }
            
        }
        
        isShowToolBar = false
    }
           
    fileprivate func hasSupview(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        return (view.superview != nil)
    }

    fileprivate func hasSupview(_ view: UIView?) -> UIView? {
        guard let view = view else { return nil }
        if (view.superview != nil) {
            return view
        }
        return nil
    }
        
}
