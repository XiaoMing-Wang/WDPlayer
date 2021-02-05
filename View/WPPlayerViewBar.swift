//
//  WPPlayerNavigationView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit

class WPPlayerViewBar: UIView {

    fileprivate var titles: String? = nil
    fileprivate weak var delegate: WPPlayerViewBarDelegate? = nil
    convenience init (titles: String, delegate: WPPlayerViewBarDelegate?) {
        self.init()
        self.titles = titles
        self.delegate = delegate
        self.initializationInterface()
    }

    /**< 初始化 */
    fileprivate func initializationInterface() {
        addSubview(topShadow)
        addSubview(backButton)
        addSubview(titleLabels)
        automaticLayout()
    }

    /// 布局
    fileprivate func automaticLayout() {
        
        topShadow.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        backButton.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(0)
            make.width.equalTo(WDPlayConf.toolBarHeight)
        }

        titleLabels.snp.makeConstraints { (make) in
            make.left.equalTo(backButton.snp.right).offset(0)
            make.right.equalToSuperview()
            make.top.bottom.equalTo(0)
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
        titleLabels.text = "电影名字阿啊啊啊啊啊啊啊啊啊 ~"
        return titleLabels
    }()

    fileprivate lazy var topShadow: UIImageView = {
        var topShadow = UIImageView()
        topShadow.image = UIImage(named: "player_top_shadow")
        return topShadow
    }()

}
