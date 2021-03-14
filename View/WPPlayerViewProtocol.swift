//
//  WPPlayerViewBarDelegate.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/26.
//

import UIKit

protocol WPPlayerViewBaseProtocol:class {
        
    /// 进度回调
    /// - Parameter currentlTime: currentlTime
    func eventValueChanged(currentlTime: Int, moving: Bool)

    /// 暂停回调
    /// - Parameter isSuspended: isSuspended
    func suspended(isSuspended: Bool)

    ///  隐藏导航栏
    func hiddenBar(hidden: Bool, isAnimation: Bool)

    ///  重置导航栏隐藏时间
    func cancelHideToolbar()
    
    ///获取当前截图
    func currentImage(currentTime: Int, results: @escaping (UIImage?, Int) -> Void)
}

protocol WPPlayerViewBarProtocol: WPPlayerViewBaseProtocol {

    /// 点击返回按钮
    func backEvent()

    /// 点击全屏按钮
    func fullEvent(isFull: Bool)
}

protocol WDPlayerTouchViewProtocol: WPPlayerViewBaseProtocol {

    ///  单击
    func singleTap(touchView: WDPlayerViewTouchControl)

    ///  双击
    func doubleTap(touchView: WDPlayerViewTouchControl)

}
