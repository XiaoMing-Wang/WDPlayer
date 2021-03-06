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
                youTbBar?.removeFromSuperview()
                
            } else {

                if toolType == .tencent {
                    
                    clipsToBounds = true
                    addSubview(topBar)
                    addSubview(toolbarView)
                    topBarDistance = WDPlayerConf.toolBarHeight
                    bottomBarDistance = WDPlayerConf.toolBarHeight
                    
                } else if let youTbBar = youTbBar {
                    
                    clipsToBounds = false
                    addSubview(youTbBar)
                    touchView.supportDoubleClick = false
                }
            }
            
            touchView.supportToolbar = isSupportToolBar
            touchView.supportDoubleClick = isSupportToolBar
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
        didSet { disPlayLoadingView(true, afterDelay: 0)  }
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
            if hasSupview(youTbBar) { youTbBar?.isSuspended = isSuspended }
        }
    }
    
    /**< 工具栏模式 */
    public var toolType: WDPlayerConf.ToolType = WDPlayerConf.toolType {
        didSet {
            if isSupportToolBar {
                isSupportToolBar = false
                isSupportToolBar = true
            }
            
            if hasSupview(touchView) {
                touchView.toolType = toolType
            }
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
    fileprivate var assetImageGenerator: AVAssetImageGenerator? = nil
    fileprivate var assetImageTime: Int = -1
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
        isSupportVolumeBrightness = false
        tag = 0

        addSubview(contentsView)
        addSubview(touchView)
        if toolType == .tencent, isSupportToolBar {
            addSubview(topBar)
            addSubview(toolbarView)
            
        } else if toolType == .youtube, isSupportToolBar, let youTbBar = youTbBar {
            insertSubview(youTbBar, aboveSubview: touchView)
            touchView.suspendIsHidden = true
            isShowToolBar = false
        }
        
        listenNotification()
        automaticLayout()
        cancelHideToolbar()
        setContentMode(.blackBorder)
        isDirectDisplayLoading = true
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

        /**< 另外的 */
        if hasSupview(youTbBar) {
            youTbBar?.fullConstraint(full: full)
        }
        
        layoutIfNeededAnimate()
    }
    
    /**< 放大 */
    fileprivate func full() {
        cancelHideToolbar()
                
        isFullScreen = true
        topBar.isFullScreen = true
        touchView.isFullScreen = true
        toolbarView.isFullScreen = true
        youTbBar?.isFullScreen = true
        originalSizePlay = frame.size
        originalCenterYPlay = WDPlayerAssistant.locationWindow_play(self).origin.y + (originalSizePlay.height / 2)
                     
        tag = WDPlayerConf.playerLayerTag
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        let fullViewController = WDPlayerFullViewController()
        fullViewController.modalPresentationStyle = .fullScreen
        if let imaView = WDPlayerAssistant.makeImageWindow_play(rootViewController?.view) {
            fullConstraint()
            if currentViewController()?.navigationController?.navigationBar.isHidden == false {
                rootViewController?.view.addSubview(imaView)
            }
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
            self.topBar.isFullScreen = false
            self.touchView.isFullScreen = false
            self.toolbarView.isFullScreen = false
            self.youTbBar?.isFullScreen = false
            self.isFullScreen = false
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
        youTbBar?.isSuspended = isSuspended
        cancelHideToolbar()
    }
    
    /**< 处理工具栏 */
    @objc fileprivate func handleBar() {
        if isShowToolBar {
            hiddenToolBar()
        } else {
            showToolBar()
            cancelHideToolbar()
        }
    }

    /**< 显示导航栏 */
    @objc fileprivate func showToolBar(_ duration: TimeInterval = 0.25) {
        if toolType == .tencent {
            hasSupview(topBar)?.snp.updateConstraints { (make) in
                make.top.equalTo(0)
            }
            
            hasSupview(toolbarView)?.snp.updateConstraints { (make) in
                make.bottom.equalTo(0)
            }
            
        } else {
            
            youTbBar?.show(duration: duration)
        }
        
        isShowToolBar = true
        touchView.hidenAllControl()
        layoutIfNeededAnimate(duration: duration)
    }
    
    /**< 隐藏导航栏 */
    fileprivate func hiddenToolBar(_ duration: TimeInterval = 0.25) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_hiddenToolBar), object: nil)
        if toolType == .tencent {
            hasSupview(topBar)?.snp.updateConstraints { (make) in
                make.top.equalTo(-topBarDistance)
            }

            hasSupview(toolbarView)?.snp.updateConstraints { (make) in
                make.bottom.equalTo(bottomBarDistance)
            }

        } else {
            youTbBar?.hide(duration: duration)
        }

        isShowToolBar = false
        layoutIfNeededAnimate(duration: duration)
    }

    /**< 隐藏导航栏 */
    @objc fileprivate func _hiddenToolBar() {
        hiddenToolBar()
    }
        
    /**< 动画转换 */
    fileprivate func layoutIfNeededAnimate(duration: TimeInterval = WDPlayerConf.playerAnimationDuration) {
        guard duration > 0 else {
            self.layoutIfNeeded()
            return
        }
        UIView.animate(withDuration: duration) { self.layoutIfNeeded() }
    }
    
    /**< 通知 */
    fileprivate func listenNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    //前台
    @objc fileprivate func didBecomeActive() {
        if hasSupview(youTbBar), let youTbBar = youTbBar {
            youTbBar.isTracking = false
            insertSubview(youTbBar, aboveSubview: touchView)
        }
    }
    
    func currentViewController(_ controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let presented = controller?.presentedViewController {
            return currentViewController(presented)
        }
        if let nav = controller as? UINavigationController {
            return currentViewController(nav.topViewController)
        }
        if let tab = controller as? UITabBarController {
            return currentViewController(tab.selectedViewController)
        }
        return controller
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
    fileprivate lazy var touchView: WDPlayerViewTouchControl = {
        var touchView = WDPlayerViewTouchControl(delegate: self)
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
extension WDPlayerLayerView: WPPlayerViewBarProtocol, WDPlayerTouchViewProtocol {
           
    /**< 进度 */
    func eventValueChanged(currentlTime: Int, moving: Bool) {
        if moving == false {
            
            if hasSupview(toolbarView) { toolbarView.currentlTime = currentlTime }
            if hasSupview(youTbBar), let youTbBar = youTbBar {
                youTbBar.isTracking = false
                youTbBar.currentlTime = currentlTime
            }
            
            if hasSupview(touchView) {
                touchView.currentlTime = currentlTime
                touchView.hidenThumView()
            }
            
            self.currentlTime = currentlTime
            delegate?.eventValueChanged(currentlTime: currentlTime)
            
        } else {
            
            disPlayLoadingView(true)
            if hasSupview(touchView) { touchView.showThumView(currentlTime: currentlTime) }
            if hasSupview(youTbBar) {  youTbBar?.isTracking = true }
        }
    }
    
    /**< 暂停播放 */
    func suspended(isSuspended: Bool) {
        self.isSuspended = isSuspended
        self.suspend(transform: false)
    }
    
    /**< 重置消失时间 */
    func cancelHideToolbar() {
        if hasSupview(topBar) || hasSupview(toolbarView) || hasSupview(youTbBar) {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_hiddenToolBar), object: nil)
            if isSuspended == false {
                perform(#selector(_hiddenToolBar), with: nil, afterDelay: 3)
            }
        }
    }
    
    /**< 隐藏导航栏 */
    func hiddenBar(hidden: Bool, isAnimation: Bool) {
        if hasSupview(topBar) || hasSupview(toolbarView) || hasSupview(youTbBar) {
            if hidden == false {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_hiddenToolBar), object: nil)
                isAnimation ? showToolBar() : showToolBar(0)
            } else {
                isAnimation ? hiddenToolBar() : hiddenToolBar(0)
            }
        }
    }
            
    /**< 单击 */
    func singleTap(touchView: WDPlayerViewTouchControl) {
        handleBar()
    }

    /**< 双击 */
    func doubleTap(touchView: WDPlayerViewTouchControl) {
        suspend()
    }
   
    /**< 返回按钮点击 */
    func backEvent() {
        if isFullScreen {
            thum()
        } else {
            backClosure?()
        }
    }

    /**< 点击全屏按钮 */
    func fullEvent(isFull: Bool) {
        isFullScreen = isFull
        isFullScreen ? full() : thum()
    }
    
    /**< 当前图片 */
    func currentImage(currentTime: Int, results: @escaping (UIImage?, Int) -> Void) {
        currentImage(second: currentTime, results: results)
    }
}

fileprivate extension WDPlayerLayerView {
    
    func hasSupview(_ view: UIView?) -> Bool {
        guard let view = view else { return false }
        return (view.superview != nil)
    }
    
    func hasSupview(_ view: UIView?) -> UIView? {
        guard let view = view else { return nil }
        if (view.superview != nil) {
            return view
        }
        return nil
    }
    
    /**< 获取某一帧率 */
    func currentImage(second: Int = 1, results: @escaping (UIImage?, Int) -> Void) {
        if assetImageTime == second { return }
        guard let asset = contentsView.playerLayer?.player?.currentItem?.asset else { return }
        if assetImageGenerator == nil {
            assetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImageGenerator?.appliesPreferredTrackTransform = true
            assetImageGenerator?.maximumSize = CGSize(width: WDPlayerConf.thumbnailWidth, height: WDPlayerConf.thumbnailWidth * 9.0 / 16.0)
            assetImageGenerator?.requestedTimeToleranceBefore = .zero
            assetImageGenerator?.requestedTimeToleranceAfter = .zero
        }

        let cmTime = CMTimeMakeWithSeconds(Float64(second), preferredTimescale: 1)
        let forTimes: [NSValue] = [NSValue(time: cmTime)]
        assetImageTime = second
        assetImageGenerator?.generateCGImagesAsynchronously(forTimes: forTimes, completionHandler: { (timer, cgImage, _, result, error) in
            if let cgImage = cgImage, error == nil {
                DispatchQueue.main.async { results(UIImage(cgImage: cgImage), second) }
            }
        })

    }
}
