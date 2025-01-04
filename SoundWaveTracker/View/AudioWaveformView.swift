//
//  AudioWaveformView.swift
//  SoundWaveTracker
//
//  Created by Grigory G. on 28.05.21.
//

import Foundation
import UIKit

final class AudioWaveformView: UIView {
    
    // MARK: - Public Properties
    var waveformData: [Float] = [] {
        didSet {
            animateWaveform(style: .centeredLines)
        }
    }
    
    // MARK: - Private Properties
    private let waveformLayer = CAShapeLayer()
    private let backgroundGradientLayer = CAGradientLayer()
    private let animationDuration: CFTimeInterval = 0.2
    private let barWidth: CGFloat = 5.0
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeLayers()
        applyCornerRadius()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initializeLayers()
        applyCornerRadius()
    }
    
    // MARK: - Layout Updates
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundGradientLayer.frame = bounds
        /// Ensure the gradient respects the corner radius
        backgroundGradientLayer.cornerRadius = Constants.viewCornerRadius
    }
    
    // MARK: - Layer Setup
    private func initializeLayers() {
        setupWaveformLayer()
        setupGradientLayer()
    }
    
    private func setupWaveformLayer() {
        waveformLayer.strokeColor = UIColor.softBlueColor.cgColor
        waveformLayer.fillColor = UIColor.clear.cgColor
        waveformLayer.lineWidth = barWidth
        waveformLayer.lineJoin = .round
        waveformLayer.lineCap = .round
        layer.addSublayer(waveformLayer)
    }
    
    private func setupGradientLayer() {
        backgroundGradientLayer.colors = [
            /// Top color
            UIColor.darkPurpleColor.cgColor,
            /// Bottom color
            UIColor.deepNightBlueColor.cgColor
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        backgroundGradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        layer.insertSublayer(backgroundGradientLayer, at: 0)
    }
    
    private func applyCornerRadius() {
        layer.cornerRadius = Constants.viewCornerRadius
        /// Ensures sublayers respect the corner radius
        layer.masksToBounds = true
    }
    
    // MARK: - Waveform Animation
    /// Animates the waveform based on the selected style.
    private func animateWaveform(style: WaveformStyle) {
        guard !waveformData.isEmpty else { return }
        /// Create a new UIBezierPath to draw the waveform
        let path = UIBezierPath()
        /// Calculate the content width available for bars
        let contentWidth = bounds.width - 4 * barWidth
        /// Calculate spacing between bars
        let barSpacing: CGFloat = (contentWidth - (AVConstants.barSpacingFactor * barWidth)) / (AVConstants.barSpacingFactor - 1)
        /// Define the maximum height available for bars
        let maxHeight = bounds.height
        /// Normalize the waveform data to fit within the height constraints
        let normalizedData = waveformData.map { CGFloat($0) / (AVConstants.magnitude + AVConstants.topLinePadding) * maxHeight }
        /// Set the initial X position for drawing bars
        var currentX: CGFloat = AVConstants.leftLinePadding + (2 * barWidth)
        /// Iterate over normalized data to draw bars or centered lines
        for height in normalizedData {
            switch style {
            case .bars:
                /// Draw bars starting from the bottom of the view
                let startPoint = CGPoint(x: currentX, y: maxHeight - AVConstants.bottomLinePadding)
                let endPoint = CGPoint(x: currentX, y: maxHeight - AVConstants.bottomLinePadding - height)
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            case .centeredLines:
                /// Draw lines extending from the center vertically
                let centerY = bounds.height / 2
                let startPoint = CGPoint(x: currentX, y: centerY - height / 2)
                let endPoint = CGPoint(x: currentX, y: centerY + height / 2)
                path.move(to: startPoint)
                path.addLine(to: endPoint)
            }
            /// Increment the X position for the next bar or line
            currentX += barWidth + barSpacing
        }
        /// Create a CABasicAnimation to animate the path changes
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = waveformLayer.path
        animation.toValue = path.cgPath
        animation.duration = animationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        /// Apply the new path and animation to the waveform layer
        waveformLayer.path = path.cgPath
        waveformLayer.add(animation, forKey: "path")
    }
    
    // MARK: - Waveform Management
    /// Clears the waveform data and removes the visual representation.
    func clearWaveform() {
        waveformLayer.path = nil
        waveformData = []
        waveformLayer.removeAllAnimations()
        setNeedsDisplay()
    }
}
