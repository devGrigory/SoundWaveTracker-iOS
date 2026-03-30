//
//  AppConstants.swift
//  SoundWaveTracker
//
//  Created by Grigory G. on 28.05.21.
//

import UIKit

struct AppConstants {
    
    // MARK: - Audio
    struct Audio {
        static let audioSourceFiles = [
            "Adriano-celentano-o-perke.mp3",
            "Holidays-in-miami.mp3",
            "Piano-moment.mp3",
            "Ricchi e Poveri - Come Vorrei.mp3",
            "Ricchi e Poveri - Sarа perche ti amo.mp3"
        ]
    }
    
    // MARK: - Audio Visualization
    struct AV {
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
    
    // MARK: - UI
    struct UI {
        static let viewCornerRadius: CGFloat = 10.0
        static let buttonCornerRadius: CGFloat = 18.0
        static let diameter: Int = 20
    }
    
    // MARK: - Images
    struct Images {
        static var pauseImage: UIImage? {
            return UIImage(systemName: "pause.fill")
        }
        static var playImage: UIImage? {
            return UIImage(systemName: "play.fill")
        }
        
        static var speakerImage: UIImage? {
            return UIImage(systemName: "volume.2.fill")
        }
        
        static var slashSpeakerImage: UIImage? {
            return UIImage(systemName: "speaker.slash.fill")
        }
    }
}
