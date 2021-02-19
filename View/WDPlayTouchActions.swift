//
//  WDPlayTouchActionView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/19.
//

import UIKit

class WDPlayTouchActionProgress: UIView {

    /**< 总时间 */
    public var totalTime: Int = 0 {
        didSet {
            totalTimeLabel.text = " / " + WDPlayerAssistant.timeTranslate(totalTime)
        }
    }

    /**< 当前时间 */
    public var currentlTime: Int = 0 {
        didSet {
            currentlTimeLabel.text = WDPlayerAssistant.timeTranslate(currentlTime)
        }
    }

    /**< 背景动画 */
    func backgroundAnimation(_ isShow: Bool = true) {
        if isShow == false {
            backgroundColor = UIColor.black.withAlphaComponent(0.0)
            return
        }
        UIView.animate(withDuration: 0.125) { self.backgroundColor = UIColor.black.withAlphaComponent(0.30) }
    }
         
    convenience init(totalTime: Int) {
        self.init()
        self.totalTime = totalTime
        self.initializationInterface()
    }
        
    fileprivate func initializationInterface() {
        self.isUserInteractionEnabled = false
        self.addSubview(currentlTimeLabel)
        self.addSubview(totalTimeLabel)
        automaticLayout()
    }

    fileprivate func automaticLayout() {
        currentlTimeLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(self.snp.centerX).offset(-5)
        }

        totalTimeLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(currentlTimeLabel.snp.right)
        }
    }
    
    public lazy var currentlTimeLabel: UILabel = {
        var currentlTimeLabel = UILabel()
        currentlTimeLabel.textAlignment = .left
        currentlTimeLabel.font = .boldSystemFont(ofSize: 28)
        currentlTimeLabel.textColor = .white
        currentlTimeLabel.numberOfLines = 1
        currentlTimeLabel.text = WDPlayerAssistant.timeTranslate(totalTime)
        return currentlTimeLabel
    }()
    
    public lazy var totalTimeLabel: UILabel = {
        var totalTimeLabel = UILabel()
        totalTimeLabel.textAlignment = .left
        totalTimeLabel.font = .boldSystemFont(ofSize: 28)
        totalTimeLabel.textColor = .white
        totalTimeLabel.numberOfLines = 1
        totalTimeLabel.text = " / " + WDPlayerAssistant.timeTranslate(totalTime)
        return totalTimeLabel
    }()

    
}
