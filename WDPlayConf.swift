//
//  WDPlayConf.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit

class WDPlayConf: NSObject {

    /**< 支持双击 */
    static var supportDoubleClick: Bool = true

    /**< 是否显示工具栏 */
    static var showTopBar: Bool = true
    static var showToolBar: Bool = true

    /**< 工具栏高度 */
    static let toolBarHeight: CGFloat = 45
    
    /**< tag */
    static let playerLayerTag: Int = 10080

    /**< 当前播放url */
    static var currentPlayURL: String? = nil

    

    enum RotaryType {

        /**< 竖屏 */
        case portrait

        /**< 横屏 */
        case landscape
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
