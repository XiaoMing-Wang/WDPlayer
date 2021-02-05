//
//  WDPlayerAssistant.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/4.
//

import UIKit

class WDPlayerAssistant: NSObject {

    /**< 实例化手势 */
    @discardableResult
    class func addTapGesture(_ target: UIView, taps: Int, touches: Int, selector: Selector) -> UITapGestureRecognizer {
        let gesture = UITapGestureRecognizer(target: target, action: selector)
        gesture.numberOfTapsRequired = taps
        gesture.numberOfTouchesRequired = touches
        target.isUserInteractionEnabled = true
        target.addGestureRecognizer(gesture)
        return gesture
    }

    /// 时间转化
    /// - Parameter duration: duration
    /// - Returns: 时间
    class func timeTranslate(_ duration: Int) -> String {
        let durationSeconds = lroundf(Float(duration))
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if durationSeconds >= 3600 {
            let hours = durationSeconds / 3600
            return String(format: "%02zd:%02zd:%02zd", hours, minutes, seconds)
        } else {
            return String(format: "%02zd:%02zd", minutes, seconds)
        }
    }

    /// window中的位置
    /// - Parameter view: view
    /// - Returns: rect
    class func locationWindow_play(_ view: UIView) -> CGRect {
        guard let window = UIApplication.shared.keyWindow else { return .zero }
        return view.convert(view.bounds, to: window)
    }
    
    /**< 截图 */
    class func makeImageWindow_play(_ view: UIView?) -> UIImageView? {
        guard let view = view else { return nil }
        let width: CGFloat = UIScreen.main.bounds.size.width
        let barHeight: CGFloat = (44 + barHeight_play())
        let imageView = UIImageView()
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: barHeight), false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: barHeight)
        UIGraphicsEndImageContext();
        return imageView
    }

    /**< 状态栏高度 */
    fileprivate class func barHeight_play() -> CGFloat {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
}
