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

class WDPlayerTouchView: UIView {

    fileprivate weak var delegate: WDPlayerTouchViewDelegate? = nil
    public var isSuspended: Bool = false {
        didSet {
            suspendButton.isHidden = !isSuspended
            if suspendButton.isHidden == false {
                hiddenLoadingView()
            }
        }
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
    }
    
    /**< 添加手势 */
    fileprivate func addGestures() {
        if WDPlayConf.supportDoubleClick {
            let singleGesture = WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(singleTap))
            let doubleGesture = WDPlayerAssistant.addTapGesture(self, taps: 2, touches: 1, selector: #selector(doubleTap))
            singleGesture.require(toFail: doubleGesture)
        } else {
            WDPlayerAssistant.addTapGesture(self, taps: 1, touches: 1, selector: #selector(doubleTap))
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
 
}
