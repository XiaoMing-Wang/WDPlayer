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
    }

    /// 设置当前时间
    /// - Parameter duration: duration
    func setCurrentDuration(_ duration: Int) {
        toolbarView.currentlTime = duration
    }

    /// 显示隐藏菊花
    /// - Parameter display: display
    func disPlayLoadingView(_ display: Bool = true, afterDelay: TimeInterval = 0.5) {
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

    /**< 双击 */
    @objc func showToolBar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
        if isShowToolBar {
            topBar.isHidden = true
            toolbarView.isHidden = true
        } else {
            topBar.isHidden = false
            toolbarView.isHidden = false
            perform(#selector(hiddenToolBar), with: nil, afterDelay: 3)
        }
        isShowToolBar = !toolbarView.isHidden
    }

    @objc func hiddenToolBar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
        UIView.animate(withDuration: 0.25) {
            self.topBar.alpha = 0
            self.toolbarView.alpha = 0
        } completion: { _ in
            self.topBar.alpha = 1
            self.toolbarView.alpha = 1
            self.topBar.isHidden = true
            self.toolbarView.isHidden = true
            self.isShowToolBar = false
        }
    }

}

/**< 工具栏回调  触摸view回调 */
extension WDPlayerLayerView: WPPlayerViewBarDelegate, WDPlayerTouchViewDelegate {

    /**< 单击 */
    func singleTap(touchView: WDPlayerTouchView) {
        if WDPlayConf.supportDoubleClick {
            showToolBar()
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

    /**< 进度滑动 */
    func eventValueChanged(currentlTime: Int) {
        delegate?.eventValueChanged(currentlTime: currentlTime)
    }

    /**< 暂停播放 */
    func suspended(isSuspended: Bool) {
        self.isSuspended = isSuspended
        self.suspend(transform: false)
    }

    /**< 取消消失工具栏 */
    func cancelHideToolbar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hiddenToolBar), object: nil)
        perform(#selector(hiddenToolBar), with: nil, afterDelay: 3)
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
        originalSizePlay = frame.size
        originalCenterYPlay = WDPlayerAssistant.locationWindow_play(self).origin.y + (originalSizePlay.height / 2)
        hiddenToolBar()

        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        let fullViewController = WDPlayerFullViewController()
        fullViewController.modalPresentationStyle = .fullScreen
        if let imaView = WDPlayerAssistant.makeImageWindow_play(rootViewController?.view) {
            rootViewController?.view.addSubview(imaView)
            rootViewController?.present(fullViewController, animated: true, completion: {
                imaView.removeFromSuperview()
            })
        }
        self.fullViewController = fullViewController
        self.fullConstraint()
    }

    /**< 还原 */
    fileprivate func thum() {
        hiddenToolBar()
        
        fullViewController?.dismiss(animated: true, completion: {
            self.fullViewController = nil
            self.fullConstraint(full: false)
        })
    }
}

class WDPlayerLayerView: UIView {

    fileprivate weak var delegate: WDPlayerLayerViewDelegate? = nil
    fileprivate var isSuspended: Bool = false
    fileprivate var isAnimation: Bool = false
    fileprivate var isShowToolBar: Bool = true
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
        setContentMode(.blackBorder)
    }

    fileprivate func automaticLayout() {
        contentsView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        touchView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalTo(0)
        }

        if WDPlayConf.showTopBar {
            topBar.snp.makeConstraints { (make) in
                make.left.right.top.equalTo(0)
                make.height.equalTo(WDPlayConf.toolBarHeight)
            }
        }

        if WDPlayConf.showToolBar {
            toolbarView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalTo(0)
                make.height.equalTo(WDPlayConf.toolBarHeight)
            }
        }
    }

    /**< 更新约束 */
    fileprivate func fullConstraint(full: Bool = true) {
        let toolBarHeight = WDPlayConf.toolBarHeight + (full ? 10 : 0)
        if WDPlayConf.showTopBar {
            topBar.snp.updateConstraints { (make) in
                make.height.equalTo(toolBarHeight)
            }
        }

        if WDPlayConf.showToolBar {
            var safeBottom: CGFloat = 0
            if #available(iOS 11, *) {
                safeBottom += UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0
            }

            toolbarView.snp.updateConstraints { (make) in
                make.bottom.equalTo((full ? -safeBottom : 0))
                make.height.equalTo(toolBarHeight)
            }
        }
    }

    /**< 播放界面 */
    fileprivate lazy var contentsView: WDPlayerContentView = {
        var contentsView = WDPlayerContentView()
        return contentsView
    }()

    /**< 顶部工具栏 */
    fileprivate lazy var topBar: WPPlayerViewBar = {
        var topBar = WPPlayerViewBar(titles: "", delegate: self)
        return topBar
    }()

    /**< 中间的触摸view */
    fileprivate lazy var touchView: WDPlayerTouchView = {
        var touchView = WDPlayerTouchView(delegate: self)
        return touchView
    }()

    /**< 底部工具栏 */
    fileprivate lazy var toolbarView: WPPlayerViewToolbar = {
        var toolbarView = WPPlayerViewToolbar(totalTime: 0, delegate: self)
        return toolbarView
    }()

}
