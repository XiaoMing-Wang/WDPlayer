//
//  WDPlayerFullTransition.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/5.
//

import UIKit

class WDPlayerFullTransition: NSObject, UIViewControllerAnimatedTransitioning {

    enum TransitionType {
        case present
        case dismiss
    }

    var type: TransitionType? = nil
    convenience init(type: TransitionType?) {
        self.init()
        self.type = type
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.30
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if self.type == .present {
            present(transitionContext: transitionContext)
        } else if self.type == .dismiss {
            dismiss(transitionContext: transitionContext)
        }
    }

    func present(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let fromView = fromVC.view,
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let toView = toVC.view,
            let playerView = fromView.viewWithTag(WDPlayConf.playerLayerTag) else {
            return
        }

        let containerView = transitionContext.containerView
        
        /**< 横屏界面还未来得及旋转 宽高是相反的 */
        let width = toView.frame.size.height
        let height = toView.frame.size.width

        let playerWidth = playerView.frame.size.height
        let playerHeight = playerView.frame.size.width
        let originalCenterXPlay = playerView.originalCenterYPlay

        /**< 横屏toView还未来得及切换宽高 */
        toView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        toView.addSubview(playerView)
        containerView.addSubview(toView)
        
        /**< 旋转缩小播放界面 让他和竖屏位置大小一致 */
        playerView.tag = WDPlayConf.playerLayerTag
        playerView.transform = CGAffineTransform.identity.rotated(by: -(CGFloat.pi / 2))
        playerView.frame = CGRect(x: 0, y: 0, width: playerWidth, height: playerHeight)
        playerView.center = CGPoint(x: originalCenterXPlay, y: playerHeight / 2)
        
        /**< 还原播放界面 */
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut) {
            toView.backgroundColor = UIColor.black.withAlphaComponent(1)
            playerView.frame = CGRect(x: 0, y: 0, width: height, height: height * WDPlayConf.playerFullProportion)
            playerView.center = CGPoint(x: width / 2, y: height / 2)
            playerView.transform = .identity
            playerView.layoutIfNeeded()
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    func dismiss(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let fromView = fromVC.view,
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let toView = toVC.view,
            let playerView = fromView.viewWithTag(WDPlayConf.playerLayerTag) else {
            return
        }
                        
        let containerView = transitionContext.containerView
        let height = toView.frame.size.width
        let width = toView.frame.size.height
        let originalWidth = playerView.originalSizePlay.height
        let originalHeight = playerView.originalSizePlay.width
        let originalCenterY = playerView.originalCenterYPlay
        
        toView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        playerView.transform = CGAffineTransform.identity.rotated(by: (CGFloat.pi / 2))
        playerView.center = CGPoint(x: width / 2, y: height / 2)
        containerView.addSubview(toView)
        containerView.addSubview(playerView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut) {
            fromView.backgroundColor = UIColor.black.withAlphaComponent(0)
            playerView.frame = CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight)
            playerView.transform = CGAffineTransform.identity
            playerView.center = CGPoint(x: width / 2, y: originalCenterY)
            playerView.layoutIfNeeded()
        } completion: { _ in
            toView.addSubview(playerView)
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
}
