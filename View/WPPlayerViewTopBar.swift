//
//  WPPlayerNavigationView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit

class WPPlayerViewTopBar: UIView {

    fileprivate var titles: String? = nil
    fileprivate weak var delegate: WPPlayerViewBarProtocol? = nil
    convenience init (titles: String, delegate: WPPlayerViewBarProtocol?) {
        self.init()
        self.titles = titles
        self.delegate = delegate
        self.initializationInterface()
    }

    /**< 全屏 */
    public var isFullScreen: Bool = false

    /**< 全屏布局 */
    public func fullConstraint(full: Bool = true) {
        clipsToBounds = !full
    }

    /**< 初始化 */
    fileprivate func initializationInterface() {
        addSubview(topShadow)
        addSubview(backButton)
        addSubview(titleLabels)
        automaticLayout()
    }

    /**< 布局 */
    fileprivate func automaticLayout() {
        topShadow.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(0)
            make.left.equalTo(-60)
            make.right.equalTo(60)
        }
        
        backButton.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(0)
            make.width.equalTo(WDPlayerConf.toolBarHeight)
        }
        
        titleLabels.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.left.equalTo(backButton.snp.right).offset(0)
            make.height.equalToSuperview()
            make.right.greaterThanOrEqualTo(-10)
        }
    }

    @objc func backClick() {
        delegate?.backClick()
    }

    fileprivate lazy var backButton: UIButton = {
        var backButton = UIButton()
        backButton.setImage(UIImage(named: "player_back_full"), for: .normal)
        backButton.addTarget(self, action: #selector(backClick), for: .touchUpInside)
        return backButton
    }()

    public lazy var titleLabels: UILabel = {
        var titleLabels = UILabel()
        titleLabels.textAlignment = .left
        titleLabels.font = .systemFont(ofSize: 15)
        titleLabels.textColor = .white
        titleLabels.numberOfLines = 1
        titleLabels.text = "电影名字~~~~~~~~~~~~"
        return titleLabels
    }()

    fileprivate lazy var topShadow: UIImageView = {
        var topShadow = UIImageView()
        topShadow.image = UIImage(named: "player_top_shadow")
        return topShadow
    }()

}
