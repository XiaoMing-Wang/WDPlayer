//
//  WPPlayerViewBarDelegate.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/26.
//

import UIKit

protocol WPPlayerViewBarProtocol: class {

    /// 进度回调
    /// - Parameter currentlTime: currentlTime
    func eventValueChanged(currentlTime: Int)

    /// 暂停回调
    /// - Parameter isSuspended: isSuspended
    func suspended(isSuspended: Bool)

    /// 取消隐藏工具栏
    func cancelHideToolbar()

    /// 隐藏工具栏
    func hideToolbar()

    /// 点击返回按钮
    func backClick()

    /// 点击全屏按钮
    func fullClick(isFull: Bool)
    
}

protocol WDPlayerTouchViewProtocol: class {

    ///  单击 
    func singleTap(touchView: WDPlayerTouchView)

    ///  双击
    func doubleTap(touchView: WDPlayerTouchView)

    ///  开始
    func resumePlay(touchView: WDPlayerTouchView)

    ///  滑动
    func slidingValue(touchView: WDPlayerTouchView)
    
    ///  进度回调
    func eventValueChanged(touchView: WDPlayerTouchView, currentlTime: Int)
    
    ///  隐藏导航栏
    func hiddenBar(touchView: WDPlayerTouchView, hidden: Bool)
}
