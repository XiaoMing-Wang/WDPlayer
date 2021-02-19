//
//  WDPlayConf.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit

class WDPlayConf: NSObject {

    static var supportDoubleClick: Bool = true /**< 是否支持双击 */
    static var supportLodaing: Bool = true   /**< 是否卡顿转圈 */
    static var showTopBar: Bool = true     /**< 是否显示工具栏 */
    static var showToolBar: Bool = true  /**< 是否显示工具栏 */
    static var supportPanGestureRecognizer: Bool = true  /**< 是否支持滑动手势 */

    /**< 进度调节 */
    static let playerProgressAdjustment: CGFloat = 240

    /**< 工具栏高度 */
    static let toolBarHeight: CGFloat = 45
    static let playerLayerTag: Int = 10080

    /**< 全屏视频比例 以手机(竖屏时)宽度为基准 */
    static let playerFullProportion: CGFloat = (16.0 / 9)
    static let playerAnimationDuration: TimeInterval = 0.30

    /**< 当前播放url */
    static var currentPlayURL: String? = nil

    static func barHeight() -> CGFloat {
        (safeBottom() > 0 ? 44 : 20) + 44
    }

    /**< 底部安全距离 */
    static func safeBottom() -> CGFloat {
        if #available(iOS 11, *) {
            return UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0
        } else {
            return 0
        }
    }

    enum ContentMode {

        /**< 用黑边填满界面 */
        case blackBorder

        /**< 全屏变形 */
        case fullScreenVariant

        /**< 全屏不变形(裁剪) */
        case fullScreenTailor
    }

}

func WDPlayStatusBarHeight() -> CGFloat {
    if #available(iOS 13, *) {
        return UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    } else {
        return UIApplication.shared.statusBarFrame.height
    }
}
