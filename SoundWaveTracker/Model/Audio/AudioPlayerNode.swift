//
//  AudioPlayerNode.swift
//  SoundWaveTracker
//
//  Created by Grigory G. on 28.05.21.
//

import Accelerate
import AVFoundation

//MARK: - Audio Playback Protocol
protocol AudioPlaybackDelegate: AnyObject {
    func didFinishPlaying()
    func didStopPlaying()
    func didChangeTrack()
}

final class AudioPlayerNode {
    
    //MARK: - Singleton
    static var shared: AudioPlayerNode = .init()
    
    //MARK: - Audio Playback Delegate
    weak var delegate: AudioPlaybackDelegate?
    
    //MARK: - Private Properties
    private let engine = AVAudioEngine()
    private let bufferSize = 1024
    private(set) var isPlaying = false
    private(set) var fftMagnitudes: [Float] = []
    
    //MARK: - Properties
    /// Property to track the current index
    var currentIndex: Int = 0 {
        didSet {
            delegate?.didChangeTrack()
        }
    }
    var isManuallyStopped = false
    let player = AVAudioPlayerNode()
    
    //MARK: - Configure Player Node
    func configurePlayerNode(with files: [AVAudioFile]) {
        /// Setup the audio engine
        setupEngine(with: files)
        /// Create an FFT configuration for complex-to-complex DFT operations
        /// What FFT Does for Audio: Audio signals are typically captured as a time-domain waveform (amplitude vs. time).
        /// What DFT Does for Audio: When applied to audio:
        ///•    Input: A chunk of audio samples (amplitude over time).
        ///•    Output: Frequency components (amplitude over frequency) as complex numbers.
        ///•    Magnitude: Represents the strength of a frequency (volume).
        ///•    Phase: Represents the timing offset of that frequency component.
        guard let fftConfiguration = vDSP_DFT_zop_CreateSetup(nil,
                                                              UInt(bufferSize),
                                                              vDSP_DFT_Direction.FORWARD) else {
            print("Failed to create FFT setup")
            return
        }
        /// Install a tap on the main mixer node to capture audio data
        engine.mainMixerNode.installTap(onBus: 0,
                                        bufferSize: UInt32(bufferSize),
                                        format: nil) { [weak self] buffer, _ in
            guard let self = self else { return }
            /// Access the audio data for the first channel
            guard let channelData = buffer.floatChannelData?[0] else {
                print("Failed to access channel data")
                return
            }
            /// Compute FFT magnitudes from the audio buffer
            self.fftMagnitudes = self.computeFFT(inputData: channelData, setup: fftConfiguration)
        }
    }
    
    private func computeFFT(inputData: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
        /// Prepare input and output buffers
        /// The output of a DFT represents the amplitude and phase of sinusoidal frequency components in the input signal. Each frequency component is a complex number: - a real part and an imaginary part
        var realPartInput = Array(UnsafeBufferPointer(start: inputData, count: bufferSize))
        var imaginaryPartInput = [Float](repeating: 0, count: bufferSize)
        var realPartOutput = [Float](repeating: 0, count: bufferSize)
        var imaginaryPartOutput = [Float](repeating: 0, count: bufferSize)
        /// Perform the FFT operation
        vDSP_DFT_Execute(setup, &realPartInput, &imaginaryPartInput, &realPartOutput, &imaginaryPartOutput)
        /// Compute magnitudes of frequency components
        var magnitudes = [Float](repeating: 0, count: AVConstants.outputCount)
        realPartOutput.withUnsafeMutableBufferPointer { realBufferPointer in
            imaginaryPartOutput.withUnsafeMutableBufferPointer { imaginaryBufferPointer in
                var complexData = DSPSplitComplex(realp: realBufferPointer.baseAddress!,
                                                  imagp: imaginaryBufferPointer.baseAddress!)
                vDSP_zvabs(&complexData, 1, &magnitudes, 1, UInt(AVConstants.outputCount))
            }
        }
        /// Normalize the magnitudes
        var normalizedMagnitudes = [Float](repeating: 0, count: AVConstants.outputCount)
        var scalingFactor: Float = 1.0
        vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(AVConstants.outputCount))
        return normalizedMagnitudes
    }
    
    private func setupEngine(with files: [AVAudioFile]) {
        /// Attach the player node to the audio engine
        engine.attach(player)
        /// Connect the player node to the main mixer node of the engine
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        do {
            /// Start the engine
            try engine.start()
        } catch {
            print("Audio Engine start error: \(error)")
        }
    }
    
    //MARK: - Audio Playback Controls
    func setVolume(to value: Float) {
        /// Adjust volume dynamically
        player.volume = value
    }
    
    func playTrack(with files: [AVAudioFile] = [], at index: Int) {
        /// Ensure the index is within the valid range
        guard index >= 0, index < files.count else { return }
        /// Stop playback if already playing
        if isPlaying {
            stopCurrentTrack()
        }
        /// Schedule the selected audio file for playback
        scheduleAudioFile(with: files)
        // Start playback
        player.play()
        isPlaying = true
        /// Reset manual stop flag after a short delay
        resetManualStopFlag(after: 1.0)
    }
    
    private func stopCurrentTrack() {
        player.stop()
        isManuallyStopped = true
    }
    
    func pausePlayback(with files: [AVAudioFile]) {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            playTrack(with: files, at: currentIndex)
        }
    }
    
    func stopPlayback() {
        player.stop()
        isPlaying = false
        delegate?.didStopPlaying()
    }
    
    func playNextTrack(with files: [AVAudioFile]) {
        guard hasNextTrack(with: files) else { return }
        currentIndex = nextTrackIndex(files)
        if !isPlaying {
            isPlaying = true
        }
        playTrack(with: files, at: currentIndex)
    }
    
    func playPreviousTrack(with files: [AVAudioFile]) {
        guard hasPreviousTrack else { return }
        currentIndex = previousTrackIndex
        if !isPlaying {
            isPlaying = true
        }
        playTrack(with: files, at: currentIndex)
    }
    
    // MARK: - Helper Methods
    /// Determines if there is a next track available.
    private func hasNextTrack(with files: [AVAudioFile]) -> Bool {
        return currentIndex < files.count - 1
    }
    
    /// Calculates the next track index, ensuring it doesn't exceed the valid range.
    private func nextTrackIndex(_ files: [AVAudioFile]) -> Int {
        return min(currentIndex + 1, files.count - 1)
    }
    
    private func scheduleAudioFile(with files: [AVAudioFile]) {
        let audioFile = files[currentIndex]
        player.scheduleFile(audioFile, at: nil) { [weak self] in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if !self.isManuallyStopped {
                    self.handlePlaybackEnded(with: files)
                }
            }
        }
    }
    
    private func resetManualStopFlag(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.isManuallyStopped = false
        }
    }
    
    private func handlePlaybackEnded(with files: [AVAudioFile]) {
        /// Automatically move to the next track when the current one ends
        if currentIndex < files.count - 1 {
            playNextTrack(with: files)
            self.delegate?.didFinishPlaying()
        } else {
            stopPlayback()
        }
    }
    
    // MARK: - Helper Properties
    /// Determines if there is a previous track available.
    private var hasPreviousTrack: Bool {
        return currentIndex > 0
    }
    
    /// Calculates the previous track index, ensuring it doesn't fall below zero.
    private var previousTrackIndex: Int {
        return max(currentIndex - 1, 0)
    }
}

