//
//  UIViewExtension.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/5.
//

import UIKit

private var originalCenterYKey: Void?
private var originalSizeKey: Void?
extension UIView {

    var originalCenterYPlay: CGFloat {
        get { return (objc_getAssociatedObject(self, &originalCenterYKey) as? CGFloat) ?? 0 }
        set { objc_setAssociatedObject(self, &originalCenterYKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var originalSizePlay: CGSize {
        get { return (objc_getAssociatedObject(self, &originalSizeKey) as? CGSize) ?? CGSize.zero }
        set { objc_setAssociatedObject(self, &originalSizeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
