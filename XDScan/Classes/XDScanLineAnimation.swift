//
//  XDScanLineAnimation.swift
//  XDScan
//
//  Created by dyw on 22/06/28.
//  Copyright © 2022年 dongyouwei. All rights reserved.
//

import UIKit

public class XDScanLineAnimation: UIImageView, XDScanAnimation {

    var isAnimationing = false
    var animationRect = CGRect.zero
    
    deinit {
        stopStepAnimating()
    }
    
    @objc func stepAnimation() {
        guard isAnimationing else {
            return
        }
        var frame = animationRect
        let hImg = image!.size.height * animationRect.size.width / image!.size.width

        frame.origin.y -= hImg
        frame.size.height = hImg
        self.frame = frame
        alpha = 0.0

        UIView.animate(withDuration: 1.4, animations: {
            self.alpha = 1.0
            var frame = self.animationRect
            let hImg = self.image!.size.height * self.animationRect.size.width / self.image!.size.width
            frame.origin.y += (frame.size.height - hImg)
            frame.size.height = hImg
            self.frame = frame
        }, completion: { _ in
            self.perform(#selector(XDScanLineAnimation.stepAnimation), with: nil, afterDelay: 0.3)
        })
    }
}

extension XDScanLineAnimation {
    
    public func stopStepAnimating() {
        isHidden = true
        isAnimationing = false
    }
    
    public func startAnimatingWithRect(animationRect: CGRect) {
        self.animationRect = animationRect
        isHidden = false
        isAnimationing = true
        if image != nil {
            stepAnimation()
        }
    }
    
}



