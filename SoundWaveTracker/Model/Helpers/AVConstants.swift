//
//  AVConstants.swift
//  SoundWaveTracker
//
//  Created by Grigory G. on 28.05.21.
//

import Foundation

struct AVConstants {
    /// Peak height of the waveform.
    static let magnitude: CGFloat = 32.0
    /// Computed property to use as an Float
    static var maxMagnitude: Float {
        return Float(magnitude)
    }
    static let leftLinePadding: CGFloat = 2.0
    static let topLinePadding: CGFloat = 10.0
    static let bottomLinePadding: CGFloat = 15.0
    /// Number of frequency components to analyze
    static let outputCount: Int = 35
    /// Computed property to use as an CGFloat
    static var barSpacingFactor: CGFloat {
        return CGFloat(outputCount)
    }
}
