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

    /**< 工具栏高度 */
    static let toolBarHeight: CGFloat = 45
    static let playerLayerTag: Int = 10080

    /**< 全屏视频比例 以手机(竖屏时)宽度为基准 */
    static let playerFullProportion: CGFloat = (16.0 / 9.0)

    /**< 当前播放url */
    static var currentPlayURL: String? = nil

    enum ContentMode {

        /**< 用黑边填满界面 */
        case blackBorder

        /**< 全屏变形 */
        case fullScreenVariant

        /**< 全屏不变形(裁剪) */
        case fullScreenTailor
    }

}
