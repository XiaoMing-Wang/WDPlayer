//
//  UIViewExtension.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/5.
//

import UIKit

private var originalCenterYKey: Void?
private var originalSizeKey: Void?
private var originalSupViewKey: Void?
extension UIView {

    var originalCenterYPlay: CGFloat {
        get { return (objc_getAssociatedObject(self, &originalCenterYKey) as? CGFloat) ?? 0 }
        set { objc_setAssociatedObject(self, &originalCenterYKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var originalSizePlay: CGSize {
        get { return (objc_getAssociatedObject(self, &originalSizeKey) as? CGSize) ?? CGSize.zero }
        set { objc_setAssociatedObject(self, &originalSizeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var originalSupView: UIView? {
        get { return (objc_getAssociatedObject(self, &originalSupViewKey) as? UIView) ?? nil }
        set { objc_setAssociatedObject(self, &originalSupViewKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
}

extension UIViewController {
    
    class func currentVC(_ controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let presented = controller?.presentedViewController {
            return currentViewController(presented)
        }

        if let nav = controller as? UINavigationController {
            return currentViewController(nav.topViewController)
        }
        if let tab = controller as? UITabBarController {
            return currentViewController(tab.selectedViewController)
        }
        
        return controller
    }
}

extension NSObject {

    /**< 取消并调用 */
    func playerCancelPrevious(selector aSelector: Selector, afterDelay: TimeInterval) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: aSelector, object: nil)
        if afterDelay != -1 { perform(aSelector, with: nil, afterDelay: afterDelay) }
    }

}
