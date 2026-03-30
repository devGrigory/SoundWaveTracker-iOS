//
//  UIView+Extension.swift
//  SoundWaveTracker
//
//  Created by Grigory G. on 30.03.26.
//

import UIKit

extension UIView {
    
    func setVerticalGradient(
        topColor: UIColor,
        bottomColor: UIColor
    ) {
        /// remove old gradients (optional but recommended)
        layer.sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }
        
        let gradient = CAGradientLayer()
        gradient.colors = [
            topColor.cgColor,
            bottomColor.cgColor
        ]
        
        /// vertical direction
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0) /// top
        gradient.endPoint   = CGPoint(x: 0.5, y: 1.0) /// bottom
        
        gradient.frame = bounds
        
        layer.insertSublayer(gradient, at: 0)
    }
}
