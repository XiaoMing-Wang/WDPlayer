//
//  WDPlayerFullViewController.swift
//  Multi-Project-Swift
//
//  Created by imMac on 2021/2/5.
//

import UIKit

class WDPlayerFullViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        transitioningDelegate = self
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .none
    }
    
}

extension WDPlayerFullViewController: UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return WDPlayerFullTransition(type: .present)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return WDPlayerFullTransition(type: .dismiss)
    }

}
