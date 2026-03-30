//
//  AudioFileService.swift
//  SoundWaveTracker
//
//  Created by Grigory G. on 28.05.21.
//

import AVFoundation

// MARK: - Protocol
protocol AudioFileServiceDelegate: AnyObject {
    func didLoadAudioFiles(_ files: [AVAudioFile])
    func didFailToLoadAudioFiles(with errors: [Error])
}

final class AudioFileService {
    
    // MARK: - Properties
    weak var delegate: AudioFileServiceDelegate?
    
    // MARK: - Methods
    /// Fetches audio file URLs from the main bundle and loads them.
    func fetchAudioFileURLs(from fileNames: [String]) {
        let urls: [URL] = fileNames.compactMap { fileName in
            guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
                print("File '\(fileName)' not found in the main bundle.")
                return nil
            }
            return url
        }
        loadAudioFiles(from: urls)
    }
    
    /// Loads audio files from the given URLs and notifies the delegate.
    private func loadAudioFiles(from urls: [URL]) {
        var loadedFiles: [AVAudioFile] = []
        var errors: [Error] = []
        urls.forEach { url in
            do {
                let file = try AVAudioFile(forReading: url)
                loadedFiles.append(file)
            } catch {
                errors.append(error)
            }
        }
        /// Notify the delegate
        if !loadedFiles.isEmpty {
            delegate?.didLoadAudioFiles(loadedFiles)
        }
        if !errors.isEmpty {
            delegate?.didFailToLoadAudioFiles(with: errors)
        }
    }
}
