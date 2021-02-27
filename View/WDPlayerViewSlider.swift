//
//  WDPlayerViewSlider.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/27.
//

import UIKit

class WDPlayerViewSlider: UISlider {

    fileprivate var lastBounds: CGRect = .zero
    fileprivate var distance: CGFloat = 10
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let result = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        lastBounds = result
        return result
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let response = super.hitTest(point, with: event)
        if (response != self) {
            if ((point.y >= -distance) && point.y < (lastBounds.size.height + distance) && (point.x >= 0 && point.x < self.bounds.width)) {
                return self
            }
        }
        return response;
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let result = super.point(inside: point, with: event)
        if (!result) {
            if ((point.x >= lastBounds.origin.x - distance) && (point.x <= lastBounds.origin.x + lastBounds.size.width + distance)) &&
                ((point.y >= -distance) && (point.y < (lastBounds.size.height + distance))) {
                return true
            }
        }
        return result
    }

}
