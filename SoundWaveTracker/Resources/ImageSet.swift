//
//  ImageSet.swift
//  SoundWaveTracker
//
//  Created by Grigory G. on 28.05.21.
//

import UIKit

// MARK: - Constants
enum ImageSet {
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

