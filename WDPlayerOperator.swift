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

    /// 缓冲失败(无法播放)
    /// - Parameter play: play
    @objc optional func bufferFail(play: WDPlayerOperator)

    /// 缓冲成功(表示这个视频可以播放)
    /// - Parameter play: play
    @objc optional func bufferSuccess(play: WDPlayerOperator)

    /// 缓冲不足(卡顿中...)
    /// - Parameter play: play
    @objc optional func bufferBufferEmpty(play: WDPlayerOperator)

    /// 缓冲足够当前视频播放
    /// - Parameter play: play
    @objc optional func bufferEnough(play: WDPlayerOperator)

    /// 进度回调(!该回调在子线程中...)
    ///   - play: 播放器
    ///   - seconds: 进度单位秒
    @objc optional func playProgress(play: WDPlayerOperator, seconds: Int)

    /// 播放结束回调
    /// - Parameter play: play
    @objc optional func playEnd(play: WDPlayerOperator)

    /// 是否正在播放(指流畅播放)
    /// - Parameters:
    ///   - play: play
    ///   - isFluentPlaying: isFluentPlaying
    @objc optional func playFluentPlaying(play: WDPlayerOperator, isFluentPlaying: Bool)

}

extension WDPlayerOperator {
    
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
        WDPlayerConf.currentPlayURL = playURL
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
        playerItem?.cancelPendingSeeks()
        player?.seek(to: CMTimeMakeWithSeconds(Float64(seconds), preferredTimescale: 1), toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: { [weak self] in
            if self?.status == .play, $0 == true {
                self?.player?.play()
            }
        })
        perform(#selector(resetTracking), with: nil, afterDelay: 1.0)
    }

    /// 释放
    func destruction(removeSuperview: Bool = true) {
        if status == .background { return }
        if playerItem == nil, player == nil {
            return
        }
        
        playerItem?.cancelPendingSeeks()
        playerItem?.asset.cancelLoading()
        if removeSuperview { playView.removeFromSuperview() }
        
        player?.pause()
        do {
            playerItem?.removeObserver(self, forKeyPath: "status")
            playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            playerItem?.removeObserver(self, forKeyPath: "playbackBufferFull")
            playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
            player?.removeObserver(self, forKeyPath: "timeControlStatus")
            player?.removeObserver(self, forKeyPath: "rate")
        } catch { }
        
        if let observerAny = self.observerAny {
            player?.removeTimeObserver(observerAny)
            self.observerAny = nil
        }

        bufferDuration = 0
        currentDuration = 0
        duration = -1
        retryCount = false
        isToKeepUp = false
        isFluentPlaying = false
        isLoadTimeControlStatus = false
                
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
        if WDPlayerConf.currentPlayURL == playURL, playURL != nil {
            WDPlayerConf.currentPlayURL = nil
        }
    }
}

fileprivate var reachabilityStatus: Bool = true
fileprivate var reachability: WDPlayerReachability? = nil
fileprivate var reachabilityCallBacks = [String?: () -> ()]()
class WDPlayerOperator: NSObject {

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
    fileprivate(set) var bufferDuration: Int = 0
    
    /**< 播放状态 */
    fileprivate(set) var status: Status = .unknow

    /**< 是否停止缓冲 */
    fileprivate var stopBuffer: Bool = false

    /**< 是否可以直接播放(缓冲足够) */
    fileprivate(set) var isToKeepUp: Bool = false
    fileprivate(set) var isLoadTimeControlStatus: Bool = false
    
    /**< 是否流畅播放 */
    fileprivate(set) var isFluentPlaying: Bool = false
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
   
    /**< 网络 */
    convenience init(playURL: String, stopBuffer: Bool = false, content: UIView? = nil) {
        self.init()
        self.stopBuffer = stopBuffer
        self.playView.setContentView(content)
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
                
                /**< 视频界面 */
                playView.delegate = self
                playView.reset()
                playView.setPlaybackLayer(player: player)
                                            
                observerAny = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .global(), using: { [weak self] progressTime in
                    guard let self = self else { return }
                    self.showPlayLoading(false)
                    guard self.isTracking == false else { return }
                    let currentDuration = lroundf(Float(CMTimeGetSeconds(progressTime)))
                    self.currentDuration = currentDuration
                    
                    /**< 设置封面 */
                    if self.playView.isSetFirstImage == false, self.getFirstRate == true {
                        self.setCover(image: WDPlayerAssistant.currentImage(currentItem: self.playerItem))
                    }
                    
                    /**< 设置秒数 */
                    if WDPlayerConf.callingPlaybackProgress {
                        if self.playURL == WDPlayerConf.currentPlayURL {
                            self.delegate?.playProgress?(play: self, seconds: currentDuration)
                        }
                    } else {
                        self.delegate?.playProgress?(play: self, seconds: currentDuration)
                    }
                                        
                    DispatchQueue.main.async {
                        self.playView.setCurrentDuration(currentDuration)
                    }
                })
                
                status = .buffer
                isToKeepUp = false
                player?.automaticallyWaitsToMinimizeStalling = false
                playerItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = false
                playerItem?.preferredForwardBufferDuration = 5
                playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
                playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
                player?.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
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
    fileprivate func getAssetDuration() {
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
    fileprivate func setCover(image: UIImage? = nil) {
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
                bufferDuration = max(bufferDuration, result)
                playView.setBufferDuration(bufferDuration)
            }
        }
    
        if (keyPath == "rate") {
            
            
        }
        
        /**< 播放状态 ios10+ */
        if (keyPath == "timeControlStatus") {
            if player?.timeControlStatus != .playing {
                isFluentPlaying = false
            }

            if player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                showPlayLoading()
            }

            isLoadTimeControlStatus = true
        }

        /**< 缓冲不足播放 */
        if (keyPath == "playbackBufferEmpty") {
            if playerItem?.isPlaybackBufferEmpty == true {
                isToKeepUp = false
                isFluentPlaying = false
                delegate?.bufferBufferEmpty?(play: self)
                
                showPlayLoading()
                playbackBufferEmpty()
                kLogPrint("playbackBufferEmpty")
            }
        }

        /**< 缓冲可以播放 */
        if (keyPath == "playbackLikelyToKeepUp") {
            if playerItem?.isPlaybackLikelyToKeepUp == true {
                isToKeepUp = true
                delegate?.bufferEnough?(play: self)
                
                if status == .play {
                    play()
                }
            } else {
                isToKeepUp = false
                isFluentPlaying = false
                showPlayLoading()
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
                    delegate?.bufferFail?(play: self)
                }
            }
        }
    }
    
    /**< 缓冲不足处理 */
    fileprivate func playbackBufferEmpty() {
        guard status == .play else { return }
        player?.pause()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(againPlay), object: nil)
        perform(#selector(againPlay), with: nil, afterDelay: 2.5)
    }

    /**< 重新播放 */
    @objc fileprivate func againPlay() {
        guard reachabilityStatus else { return }
        guard status == .play else { return }
        guard isFluentPlaying == false else { return }
        if playerItem?.isPlaybackLikelyToKeepUp == true {
            player?.play()
        } else {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(againPlay), object: nil)
            perform(#selector(againPlay), with: nil, afterDelay: 3)
        }
    }

    /**< 显示菊花 */
    fileprivate func showPlayLoading(_ disPlay: Bool = true) {
        DispatchQueue.main.async {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.showLoading), object: nil)
            if disPlay {
                self.perform(#selector(self.showLoading), with: nil, afterDelay: 0.3)
            } else {
                self.isFluentPlaying = true
                self.playView.disPlayLoadingView(false)
                self.delegate?.playFluentPlaying?(play: self, isFluentPlaying: true)
            }
        }
    }
    
    @objc fileprivate func showLoading() {
        isFluentPlaying = false
        playView.disPlayLoadingView(true)
        delegate?.playFluentPlaying?(play: self, isFluentPlaying: false)
    }

    deinit {
        status = .pause
        destruction(removeSuperview: true)
    }
    
    /**< 网络状态 */
    fileprivate func reachabilityState(playURL: String?) {
        guard reachability == nil else {
            reachabilityCallBacks[playURL] = getCallBack()
            return
        }

        reachabilityCallBacks[playURL] = getCallBack()
        reachability = try? WDPlayerReachability(hostname: "www.baidu.com")
        reachability?.whenReachable = { _ in
            reachabilityStatus = true
            for (_, reachabilityCallBack) in reachabilityCallBacks {
                reachabilityCallBack()
            }
        }
        
        reachability?.whenUnreachable = { _ in
            reachabilityStatus = false
        }
        try? reachability?.startNotifier()
    }
    
    fileprivate func getCallBack() -> (() -> ()) {
        reachabilityCallBack = { [weak self] in
            if self?.status == .fail {
                self?.playView.disPlayLoadingView(true)
                self?.retryloade()
            }

            if self?.status == .play, self?.isFluentPlaying == false {
                self?.player?.pause()
                self?.player?.play()
            }
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
        if let item = notification.object as? AVPlayerItem, item == playerItem {
            backBagin(mandatory: true)
            delegate?.playEnd?(play: self)
            
            if isReplay, status == .play {
                play()
            } else if isReplay == false {
                stop()
            }
        }
    }

    /**< 后台 */
    @objc fileprivate func resignActive() {
        if status == .play {
            pause()
            status = .background
            /**< playView.isSuspended = true */
        }
    }
    
    /**< 前台 */
    @objc fileprivate func becomeActive() {
        if status == .background {
            play()
            /**< playView.isSuspended = false */
        }
    }

    /**< 重置 */
    @objc func resetTracking() {
        isTracking = false
    }
}

extension WDPlayerOperator: WDPlayerLayerViewDelegate {

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
