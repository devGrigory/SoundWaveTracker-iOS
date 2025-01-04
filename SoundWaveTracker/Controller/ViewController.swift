//
//  ViewController.swift
//  SoundWaveTracker
//
//  Created by Grigory G. on 28.05.21.
//

import AVFoundation
import Foundation
import UIKit

class ViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var artistTitleLabel: UILabel!
    @IBOutlet private weak var previousButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var volumeSlider: UISlider!
    @IBOutlet private weak var volumeImageView: UIImageView!
    @IBOutlet private weak var slidableView: UIView!
    @IBOutlet private weak var slideableWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var slidableContainerView: UIView!
    @IBOutlet private weak var controlsView: UIView!
    @IBOutlet private weak var waveformView: AudioWaveformView!
    
    //MARK: - Private Properties
    private var audioFiles: [AVAudioFile] = []
    private let audioFileService = AudioFileService()
    private let audioPlayer = AudioPlayerNode.shared
    private var playbackTimer: Timer?
    private var timeInterval: Double = 0.01
    private var currentPlaybackTime: Double = 0.0
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        configureDelegates()
        configureAudioServices()
    }
    
    //MARK: - IB Actions
    @IBAction func playPreviousButtonAction(_ sender: UIButton) {
        playPreviousAudio()
    }
    
    @IBAction func playPauseButtonAction(_ sender: UIButton) {
        if audioPlayer.isPlaying {
            pauseAudioPlaybackAndTimer()
        } else {
            startAudioPlaybackAndTimer()
        }
    }
    
    @IBAction func playNextButtonAction(_ sender: UIButton) {
        playNextAudio()
    }
    
    @IBAction func volumeSliderChanged(_ sender: UISlider) {
        /// Range from 0.0 to 1.0
        let volumeValue = sender.value
        audioPlayer.setVolume(to: volumeValue)
        updateVolumeIcon(for: volumeValue)
    }
    
    //MARK: - Private Methods
    private func updateUI() {
        previousButton.layer.cornerRadius = Constants.buttonCornerRadius
        playPauseButton.layer.cornerRadius = Constants.buttonCornerRadius
        nextButton.layer.cornerRadius = Constants.buttonCornerRadius
        controlsView.layer.cornerRadius = Constants.viewCornerRadius
        let thumbImage = createRoundedThumbImage()
        /// Ensure same thumb image for states
        volumeSlider.setThumbImage(thumbImage, for: .normal)
        volumeSlider.setThumbImage(thumbImage, for: .highlighted)
        volumeSlider.setThumbImage(thumbImage, for: .selected)
        previousButton.isEnabled = false
    }
    
    /// Create a custom thumb image with rounded corners
    private func createRoundedThumbImage() -> UIImage {
        let thumbSize = CGSize(width: Constants.diameter, height: Constants.diameter)
        /// Create a renderer to draw the thumb image
        let renderer = UIGraphicsImageRenderer(size: thumbSize)
        /// Create the image with rounded corners
        return renderer.image { _ in
            /// Set color (change to desired color)
            UIColor.softLavender.setFill()
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: thumbSize),
                                    cornerRadius: thumbSize.width / 2)
            path.fill()
        }
    }
    
    /// Configure delegates for audio services
    private func configureDelegates() {
        audioPlayer.delegate = self
        audioFileService.delegate = self
    }

    /// Configure and start audio services
    private func configureAudioServices() {
        /// Start loading files
        audioFileService.fetchAudioFileURLs(from: AudioConstants.audioSourceFiles)
        audioPlayer.configurePlayerNode(with: audioFiles)
    }
    
    private func startAudioPlaybackAndTimer() {
        /// Start visualizing audio playback
        initiateAudioPlaybackVisualization()
        /// Start audio playback from the beginning (or a specific position)
        audioPlayer.playTrack(with: audioFiles, at: audioPlayer.currentIndex)
        //playPauseButton.setImage(UIImage(systemName:"pause.fill"), for: .normal)
        updateButtonStates()
    }
    
    private func initiateAudioPlaybackVisualization() {
        //guard let audioFile = try? AVAudioFile(forReading: audioFileURLs[audioPlayer.currentIndex]) else { return }
        let audioFile = audioFiles[audioPlayer.currentIndex]
        /// Get total duration of the audio file in seconds
        let totalDuration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        playbackTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                /// Update FFT visualization (if applicable)
                self.waveformView.waveformData = audioPlayer.fftMagnitudes.map { min($0, AVConstants.maxMagnitude) }
                /// Dynamically calculate elapsed time
                guard let nodeTime = audioPlayer.player.lastRenderTime,
                      let playerTime = audioPlayer.player.playerTime(forNodeTime: nodeTime) else {
                    return
                }
                /// Calculate elapsed time in seconds based on sample time and sample rate
                let elapsedSamples = Double(playerTime.sampleTime)
                self.currentPlaybackTime = elapsedSamples / playerTime.sampleRate
                /// Calculate playback progress as a ratio of current time to total duration
                let playbackProgress = self.currentPlaybackTime / totalDuration
                // Update the progress view or UI
                self.updatePlaybackProgress(with: playbackProgress)
            }
        refreshArtistName(for: audioFiles[audioPlayer.currentIndex])
    }
    
    private func playNextAudio() {
        audioPlayer.isManuallyStopped = true
        updateButtonStates()
        cancelPlaybackTimer()
        audioPlayer.playNextTrack(with: audioFiles)
        initiateAudioPlaybackVisualization()
    }
    
    private func playPreviousAudio() {
        audioPlayer.isManuallyStopped = true
        updateButtonStates()
        cancelPlaybackTimer()
        audioPlayer.playPreviousTrack(with: audioFiles)
        initiateAudioPlaybackVisualization()
    }
    
    /// Pauses the playback timer.
    private func pauseAudioPlaybackAndTimer() {
        cancelPlaybackTimer()
        audioPlayer.pausePlayback(with: audioFiles)
        updateButtonStates()
    }
    
    /// Cancels the playback timer if it's active.
    private func cancelPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func refreshArtistName(for audioFile: AVAudioFile) {
        let asset = AVAsset(url: audioFile.url)
        /// Extract common metadata
        let metadata = asset.commonMetadata
        /// Find artist information in metadata
        guard let artistMetadata = metadata.first(where: { $0.commonKey?.rawValue == "artist" }),
              let artistName = artistMetadata.stringValue else {
            artistTitleLabel.text = "Unknown Artist"
            return
        }
        /// Update the label with the artist name
        artistTitleLabel.text = artistName
    }
    
    private func updatePlaybackProgress(with playbackProgress: Double) {
        let width = slidableContainerView.bounds.width
        self.slideableWidthConstraint.constant =  width * playbackProgress
        self.slidableView.layoutIfNeeded()
    }
    
    private func updateVolumeIcon(for volumeValue: Float) {
        volumeImageView.image = (volumeValue == 0.0) ? ImageSet.slashSpeakerImage : ImageSet.speakerImage
    }
    
    private func updateButtonStates() {
        // Update play/pause button image
        let playPauseImage: UIImage?
        if audioPlayer.isPlaying || audioPlayer.isManuallyStopped {
            playPauseImage = ImageSet.pauseImage
        } else {
            playPauseImage = ImageSet.playImage
        }
        playPauseButton.setImage(playPauseImage, for: .normal)
        // Update previous and next button states
        previousButton.isEnabled = audioPlayer.currentIndex > 0
        nextButton.isEnabled = audioPlayer.currentIndex < audioFiles.count - 1
    }
}

//MARK: - AudioPlayback Delegate Implementation
extension ViewController: AudioPlaybackDelegate {
    func didFinishPlaying() {
        cancelPlaybackTimer()
        initiateAudioPlaybackVisualization()
    }
    
    func didStopPlaying() {
        cancelPlaybackTimer()
        artistTitleLabel.text = nil
        waveformView.clearWaveform()
        updatePlaybackProgress(with: 0.0)
        audioPlayer.currentIndex = 0
        updateButtonStates()
    }
    
    func didChangeTrack() {
        updateButtonStates()
    }
}

//MARK: - AudioFile Service Delegate Implementation
extension ViewController: AudioFileServiceDelegate {
    func didLoadAudioFiles(_ files: [AVAudioFile]) {
        /// Successfully loaded files
        audioFiles = files
    }
    
    func didFailToLoadAudioFiles(with errors: [any Error]) {
        /// Handle errors
        for error in errors {
            print("Failed to load audio file: \(error.localizedDescription)")
        }
    }
}


