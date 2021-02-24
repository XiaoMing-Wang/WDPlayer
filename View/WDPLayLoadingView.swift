//
//  WDPLayLoadingView.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/5.
//

import UIKit

class WDPLayLoadingView: UIView {
    
    static var share: WDPLayLoadingView? = WDPLayLoadingView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
    fileprivate var displayLink: CADisplayLink? = nil
    fileprivate var animationLayer: CAShapeLayer? = nil
    fileprivate var startAngle: Double = 0
    fileprivate var endAngle: Double = 0
    fileprivate var progress: Double = 0
    fileprivate var isPlaying: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func start() {
        guard isPlaying == false else { return }
        isPlaying = true
        displayLink?.isPaused = false
        isHidden = false
    }

    func hide() {
        progress = 0
        isPlaying = false
        displayLink?.isPaused = true
        isHidden = true
        updateAnimationLayer()
    }

    func initialize() {
        animationLayer = CAShapeLayer()
        animationLayer?.frame = bounds
        animationLayer?.fillColor = UIColor.clear.cgColor
        animationLayer?.strokeColor = UIColor.white.cgColor;
        animationLayer?.lineWidth = 2;
        animationLayer?.lineCap = CAShapeLayerLineCap.round;
        layer.addSublayer(animationLayer!)

        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkAction))
        displayLink?.add(to: .main, forMode: .default)
    }

    @objc func displayLinkAction() {
        progress += self.speed()
        if progress >= 1 { progress = 0 }
        updateAnimationLayer()
    }

    func updateAnimationLayer() {
        let pi_2 = Double.pi * 0.5
        let pi2T = Double.pi * 2
        startAngle = -pi_2
        endAngle = -pi_2 + progress * pi2T

        if (endAngle > .pi) {
            let progress1 = 1 - (1 - progress) / 0.25
            startAngle = -pi_2 + progress1 * pi2T
        }

        let width = animationLayer?.bounds.size.width ?? 0
        let height = animationLayer?.bounds.size.height ?? 0
        let lineWidth = (animationLayer?.lineWidth ?? 0)
        let radius = width / 2.0 - lineWidth / 2
        let x = width / 2.0
        let y = height / 2.0
        let path = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: radius, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: true)
        path.lineCapStyle = .round
        animationLayer?.path = path.cgPath
    }

    func speed() -> Double {
        if endAngle > .pi { return 0.3 / 60.0 }
        return 2 / 60.0
    }

    
    
}
