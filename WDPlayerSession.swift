//
//  WPPlayer.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit
import AVFoundation
import KTVHTTPCache

@objc protocol WDPlayerSessionDelegate {

    /**< 缓冲失败(链接失效) */
    @objc optional func bufferFail(play: WDPlayerSession)

    /**< 缓冲成功(表示这个视频可以播放) */
    @objc optional func bufferSuccess(play: WDPlayerSession)

    /**< 缓冲不足(显示菊花) */
    @objc optional func bufferBufferEmpty(play: WDPlayerSession)

    /**< 缓冲足够当前视频播放  */
    @objc optional func bufferEnough(play: WDPlayerSession)

    /// 进度回调
    /// - Parameters:
    ///   - play: 播放器
    ///   - seconds: 进度单位秒
    @objc optional func playProgress(play: WDPlayerSession, seconds: Int)
}

extension WDPlayerSession {
    
    /**< 播放 */
    func play() {

        /**< 用户手动暂停的 不允许播放 */
        if status == .initiative { return }
        if status == .wait {
            backBagin(mandatory: true)
        }

        player?.play()
        status = .play
        stopBuffer = false
        /**< playerItem?.preferredForwardBufferDuration = 0 */
        /**< playerItem?.preferredPeakBitRate = TimeInterval(100000) */
        /**< 当前播放的资源 */
        WDPlayConf.currentPlayURL = playURL
    }
    
    /**< 暂停 */
    func pause() {

        /**< 用户手动暂停的  */
        if status == .initiative { return }
        player?.pause()
        status = .pause
    }
    
    /**< 把进度设置到最后 */
    func stop() {
        status = .wait
        stopBuffer = true
        /**< playerItem?.preferredForwardBufferDuration = TimeInterval(0.1) */
        /**< playerItem?.preferredPeakBitRate = 1 */
        /**< playerItem?.seek(to: CMTimeMakeWithSeconds(100000, preferredTimescale: 1)) */
        /**< player?.seek(to: CMTimeMakeWithSeconds(100000, preferredTimescale: 1)) */
        playerItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        playerItem?.cancelPendingSeeks()
        playerItem?.asset.cancelLoading()
        player?.pause()
    }
    
    /**< 回到开头 */
    func backBagin(mandatory: Bool = false) {
        if status == .play, mandatory == false { return }
        playerItem?.seek(to: .zero)
        player?.seek(to: .zero)
    }
    
    /**< 切换 */
    func replacePlayURL(_ nextURL: String?) {
        if nextURL == playURL, status != .fail {
            return
        }
        
        guard let nextURL = nextURL else {
            destruction()
            return
        }

        kLogPrint(3333333)
        replaceItem(playURL: nextURL)
    }
    
    /// 重试
    func retryloade() {
        replacePlayURL(playURL)
    }
    
    /// 快进/退
    /// - Parameter seconds: seconds
    func seekSeconds(seconds: Int) {
        isTracking = true
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(resetTracking), object: nil)

        player?.pause()
        player?.seek(to: CMTimeMakeWithSeconds(Float64(seconds), preferredTimescale: 1), toleranceBefore: .zero, toleranceAfter: .zero)
        if status == .play {
            player?.play()
        }
        perform(#selector(resetTracking), with: nil, afterDelay: 1.0)
    }

    /// 释放
    func destruction(removeSuperview: Bool = true) {
        if status == .background { return }
        if playerItem == nil, player == nil {
            return
        }
        
        player?.pause()
        do {
            playerItem?.removeObserver(self, forKeyPath: "status")
            playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            playerItem?.removeObserver(self, forKeyPath: "playbackBufferFull")
            playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
            player?.removeObserver(self, forKeyPath: "timeControlStatus")
        } catch {}

        if let observerAny = self.observerAny {
            player?.removeTimeObserver(observerAny)
            self.observerAny = nil
        }

        status = .destruction
        playerLayer?.removeFromSuperlayer()
        playURL = nil
        proxyUrl = nil
        playerItem = nil
        playerLayer = nil
        player?.replaceCurrentItem(with: nil)
        player = nil
        playView.reset()
        reachabilityCallBacks[playURL] = nil
        
        NotificationCenter.default.removeObserver(self)
        if WDPlayConf.currentPlayURL == playURL, playURL != nil {
            WDPlayConf.currentPlayURL = nil
        }
    }
}

fileprivate var reachability: WDPlayerReachability? = nil
fileprivate var reachabilityCallBacks = [String?: () -> ()]()
class WDPlayerSession: NSObject {

    enum Status {
        case unknow      /**< 未知 */
        case buffer      /**< 缓冲 */
        case wait        /**< 等待播放 */
        case pause       /**< 系统暂停 */
        case initiative  /**< 手动暂停 */
        case play        /**< 播放 */
        case fail        /**< 失败 */
        case background  /**< 进入后台 */
        case destruction /**< 释放无任务 */
    }

    /**< 回调代理 */
    public var delegate: WDPlayerSessionDelegate? = nil

    /**< 播放view */
    public var playView: WDPlayerLayerView = WDPlayerLayerView()

    /**< 是否获取第一帧 */
    public var getFirstRate: Bool = false {
        didSet {
            if getFirstRate { setCover() }
        }
    }

    /**< 自动播放 */
    public var isAutoPlay: Bool = true

    /**< 是否重播 */
    public var isReplay: Bool = true

    /**< 总时长 */
    fileprivate(set) var duration: Int = -1
    fileprivate(set) var currentDuration: Int = 0
    
    /**< 播放状态 */
    fileprivate(set) var status: Status = .unknow

    /**< 是否停止缓冲 */
    fileprivate var stopBuffer: Bool = false

    /**< 是否可以直接播放(缓冲足够) */
    fileprivate(set) var isToKeepUp: Bool = false
    fileprivate(set) var isLoadTimeControlStatus: Bool = false
    
    /**< 是否处于卡顿状态 */
    fileprivate(set) var isCaton: Bool = false
    fileprivate(set) var isTracking: Bool = false

    /**< 播放资源 */
    fileprivate(set) var playURL: String? = nil
    fileprivate(set) var proxyUrl: URL? = nil

    /**< 失败重试次数 */
    fileprivate var retryCount: Bool = false
    fileprivate var player: AVPlayer? = nil
    fileprivate var playerLayer: AVPlayerLayer? = nil
    fileprivate var playerItem: AVPlayerItem? = nil
    fileprivate var observerAny: Any? = nil
    fileprivate var reachabilityCallBack: (() -> ())? = nil
    fileprivate weak var backgroundView: UIView? = nil

    /**< 网络 */
    convenience init(playURL: String, stopBuffer: Bool = false, background: UIView? = nil) {
        self.init()
        self.stopBuffer = stopBuffer
        self.backgroundView = background
        self.replaceItem(playURL: playURL)
    }

    /**< 切换item 网络路径转化成本地路径 */
    fileprivate func replaceItem(playURL: String) {
        destruction()
        reachabilityState(playURL: playURL)
        listenNotification()
        
        self.playURL = playURL
        if let url = URL(string: playURL) {
            if let proxyUrl = KTVHTTPCache.proxyURL(withOriginalURL: url) {
                self.proxyUrl = proxyUrl
                playerItem = AVPlayerItem(url: proxyUrl)
                player = AVPlayer(playerItem: playerItem)
                playerLayer = AVPlayerLayer(player: player)
                kLogPrint("视频准备播放...\(playURL)")
                
                /**< 视频界面大小和backgroundView一致 */
                playView.delegate = self
                playView.reset()
                playView.setPlaybackLayer(player: player)
                playView.frame = backgroundView?.bounds ?? .zero
                backgroundView?.addSubview(playView)
                backgroundView?.isUserInteractionEnabled = true
                               
                observerAny = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .global(), using: { [weak self] progressTime in
                    guard self?.isTracking == false, let self = self else { return }
                    let currentDuration = lroundf(Float(CMTimeGetSeconds(progressTime)))
                    self.currentDuration = currentDuration
                    
                    /**< 设置封面 */
                    if self.playView.isSetFirstImage == false, self.getFirstRate == true {
                        self.setCover(image: WDPlayerAssistant.currentImage(currentItem: self.playerItem))
                    }
                    
                    /**< 设置秒数 */
                    self.delegate?.playProgress?(play: self, seconds: currentDuration)
                    DispatchQueue.main.async {
                        self.playView.setCurrentDuration(currentDuration)
                    }
                })
                
                duration = -1
                status = .buffer
                isToKeepUp = false
                playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
                player?.addObserver(self, forKeyPath: "timeControlStatus", options: .new, context: nil)
                if stopBuffer { stop() }
            }
        }
        
        /**< 静音播放 */
        if AVAudioSession.sharedInstance().category != .playback {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
        }
    }
    
    /**< 获取时长 */
    func getAssetDuration() {
        guard duration == -1 else { return }
        DispatchQueue.global().async {
            if let assetDuration = self.playerItem?.asset.duration {
                let duration = lroundf(Float(CMTimeGetSeconds(assetDuration)))
                self.duration = duration
                DispatchQueue.main.async {
                    self.playView.setTotalDuration(duration)
                }
            }
        }
    }
    
    /**< 设置封面 */
    func setCover(image: UIImage? = nil) {
        if let image = image {
            playView.setFirstImage(image, forkey: playURL)
        } else  {
            playView.setCoverUrl(coverUrl: playURL, local: true)
        }
    }
    
    /**< 监听回调 */
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        /**< 缓冲区域 */
        if (keyPath == "loadedTimeRanges") {
            let loadedTimeRanges = playerItem?.loadedTimeRanges
            if let timeRange = loadedTimeRanges?.first?.timeRangeValue {
                let startSeconds = CMTimeGetSeconds(timeRange.start)
                let durationSeconds = CMTimeGetSeconds(timeRange.duration)
                let result = Int(startSeconds + durationSeconds)
                playView.setBufferDuration(result)
            }
        }

        /**< 播放状态 ios10+ */
        if (keyPath == "timeControlStatus") {
            if player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                isCaton = true
            } else {
                isCaton = false
                delegate?.bufferEnough?(play: self)
            }
            playView.disPlayLoadingView(isCaton)
            isLoadTimeControlStatus = true
        }

        /**< 缓冲不足播放 */
        if (keyPath == "playbackBufferEmpty") {
            if playerItem?.isPlaybackBufferEmpty == true {
                isToKeepUp = false
                isCaton = true
                delegate?.bufferBufferEmpty?(play: self)
            }
        }

        /**< 缓冲可以播放 */
        if (keyPath == "playbackLikelyToKeepUp") {
            if playerItem?.isPlaybackLikelyToKeepUp == true {
                isToKeepUp = true
                isCaton = false

                /**< 缓冲足够假如处于暂停 需要播放的播放视频 */
                if status == .play, player?.timeControlStatus == .paused {
                    play()
                }
            }
        }
        
        /**< 状态 */
        if (keyPath == "status") {
            if playerItem?.status == .readyToPlay, status == .play || isAutoPlay {
                play()
                getAssetDuration()
                retryCount = false
                delegate?.bufferSuccess?(play: self)
                
            } else if playerItem?.status == .readyToPlay, status == .buffer || status == .wait {
                stop()
                getAssetDuration()
                retryCount = false
                delegate?.bufferSuccess?(play: self)
                               
            } else if playerItem?.status == .failed || playerItem?.status == .unknown {
                
                status = .fail
                kLogPrint("视频缓冲失败 :\(playURL!)")
                kLogPrint("视频缓冲失败 :\(playerItem!.error.debugDescription)")
                if (playerItem?.error as NSError?)?.code == -11829, retryCount == false, let _ = playURL {
                    
                    retryCount = true
                    retryloade()
                    
                } else {
                    
                    /**< 缓存失败 */
                    delegate?.bufferFail?(play: self)
                }
            }
        }

    }

    deinit {
        status = .pause
        destruction()
    }
    
    /**< 网络状态 */
    func reachabilityState(playURL: String?) {
        guard reachability == nil else {
            reachabilityCallBacks[playURL] = getCallBack()
            return
        }

        reachabilityCallBacks[playURL] = getCallBack()
        reachability = try? WDPlayerReachability(hostname: "www.baidu.com")
        reachability?.whenReachable = { _ in
            for (_, reachabilityCallBack) in reachabilityCallBacks {
                reachabilityCallBack()
            }
        }
        try? reachability?.startNotifier()
    }
    
    fileprivate func getCallBack() -> (() -> ()) {
        reachabilityCallBack = { [weak self] in
            if self?.status == .fail { self?.retryloade() }
        }
        return reachabilityCallBack!
    }
    
    /**< 通知 */
    fileprivate func listenNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(becomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    /**< 播放结束 */
    @objc fileprivate func playerItemDidReachEnd(notification: Notification) {
        backBagin(mandatory: true)
        if isReplay, status == .play {
            play()

        } else if isReplay == false {
            stop()
        }
    }

    /**< 后台 */
    @objc fileprivate func resignActive() {
        if status == .play {
            pause()
            status = .background
        }
    }
    
    /**< 前台 */
    @objc fileprivate func becomeActive() {
        if status == .background {
            play()
        }
    }

    /**< 重置 */
    @objc func resetTracking() {
        isTracking = false
    }
}

extension WDPlayerSession: WDPlayerLayerViewDelegate {

    /// 暂停回调
    /// - Parameter layerView: layerView
    func suspended(layerView: WDPlayerLayerView) {
        status = .initiative
        player?.pause()
    }

    /// 播放回调
    /// - Parameter layerView: layerView
    func play(layerView: WDPlayerLayerView) {
        status = .play
        player?.play()
    }

    /// 进度
    /// - Parameters:
    ///   - layerView: layerView
    ///   - currentlTime: currentlTime
    func eventValueChanged(currentlTime: Int) {
        seekSeconds(seconds: currentlTime)
    }

    
}
