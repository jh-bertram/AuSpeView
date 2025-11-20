//
//  AudioEngine.swift
//  AudioVisualizer
//
//  Created on 2025-11-19.
//

import AVFoundation
import Accelerate

@MainActor
class AudioEngine: ObservableObject {
    @Published var frequencyBands: [Float] = Array(repeating: 0, count: 16)

    // Sensitivity multiplier (applied after normalization)
    var sensitivity: Float = 1.0

    // Configurable dB range for visualization
    var minDB: Float = -80  // Noise floor (for ambient mic capture)
    var maxDB: Float = -30  // Loud sounds

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?

    // FFT setup
    private let fftSize: Int = 2048
    private var fftSetup: vDSP_DFT_Setup?
    private var hanningWindow: [Float] = []

    // Buffers for FFT processing
    private var realIn: [Float] = []
    private var imagIn: [Float] = []
    private var realOut: [Float] = []
    private var imagOut: [Float] = []

    // Frequency band boundaries (logarithmically distributed from ~20Hz to 20kHz)
    private var bandFrequencies: [Float] = []

    private var isRunning = false
    private var sampleRate: Float = 44100

    init() {
        setupFFT()
        calculateBandFrequencies()
    }

    deinit {
        // Clean up audio engine synchronously without calling MainActor-isolated stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        if let setup = fftSetup {
            vDSP_DFT_DestroySetup(setup)
        }
    }

    private func setupFFT() {
        // Create DFT setup for forward FFT
        fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            vDSP_Length(fftSize),
            vDSP_DFT_Direction.FORWARD
        )

        // Create Hanning window to reduce spectral leakage
        hanningWindow = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&hanningWindow, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))

        // Initialize buffers
        realIn = [Float](repeating: 0, count: fftSize)
        imagIn = [Float](repeating: 0, count: fftSize)
        realOut = [Float](repeating: 0, count: fftSize)
        imagOut = [Float](repeating: 0, count: fftSize)
    }

    private func calculateBandFrequencies() {
        // Create 17 boundary frequencies for 16 bands
        // Logarithmically distributed from 20Hz to 20kHz
        let minFreq: Float = 20.0
        let maxFreq: Float = 20000.0
        let numBands = 16

        bandFrequencies = []
        for i in 0...numBands {
            let ratio = Float(i) / Float(numBands)
            let freq = minFreq * pow(maxFreq / minFreq, ratio)
            bandFrequencies.append(freq)
        }
    }

    func requestPermissionAndStart() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                if granted {
                    self?.start()
                } else {
                    print("Microphone permission denied")
                }
            }
        }
    }

    func start() {
        guard !isRunning else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
            try session.setActive(true)

            // Get the actual sample rate
            sampleRate = Float(session.sampleRate)

            audioEngine = AVAudioEngine()
            guard let engine = audioEngine else { return }

            inputNode = engine.inputNode
            guard let input = inputNode else { return }

            let format = input.outputFormat(forBus: 0)
            sampleRate = Float(format.sampleRate)

            // Install tap on input node
            input.installTap(onBus: 0, bufferSize: UInt32(fftSize), format: format) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }

            try engine.start()
            isRunning = true

            // Setup interruption handling
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: nil
            )

        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }

        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        isRunning = false

        NotificationCenter.default.removeObserver(self)

        // Reset bands
        Task { @MainActor in
            frequencyBands = Array(repeating: 0, count: 16)
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        Task { @MainActor in
            switch type {
            case .began:
                stop()
            case .ended:
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        start()
                    }
                }
            @unknown default:
                break
            }
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0],
              let setup = fftSetup else { return }

        let frameCount = Int(buffer.frameLength)
        let samplesToProcess = min(frameCount, fftSize)

        // Copy audio data and apply Hanning window
        for i in 0..<samplesToProcess {
            realIn[i] = channelData[i] * hanningWindow[i]
        }

        // Zero-pad if necessary
        for i in samplesToProcess..<fftSize {
            realIn[i] = 0
        }

        // Clear imaginary input
        for i in 0..<fftSize {
            imagIn[i] = 0
        }

        // Perform FFT
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)

        // Calculate magnitudes
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)

        realOut.withUnsafeBufferPointer { realPtr in
            imagOut.withUnsafeBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(
                    realp: UnsafeMutablePointer(mutating: realPtr.baseAddress!),
                    imagp: UnsafeMutablePointer(mutating: imagPtr.baseAddress!)
                )
                vDSP_zvabs(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
            }
        }

        // Apply proper FFT scaling
        let scaleFactor = 2.0 / Float(fftSize)
        for i in 0..<magnitudes.count {
            magnitudes[i] *= scaleFactor
        }

        // Convert to dB and normalize
        let bands = calculateBands(from: magnitudes)

        // Get current settings
        let currentSensitivity = sensitivity

        Task { @MainActor in
            // Smooth the values for visual appeal
            for i in 0..<16 {
                // Apply sensitivity multiplier after normalization
                let target = min(1.0, bands[i] * currentSensitivity)
                let current = frequencyBands[i]
                // Smoothing: fast attack, slow release
                if target > current {
                    frequencyBands[i] = current + (target - current) * 0.7
                } else {
                    frequencyBands[i] = current + (target - current) * 0.15
                }
            }
        }
    }

    private func calculateBands(from magnitudes: [Float]) -> [Float] {
        var bands = [Float](repeating: 0, count: 16)
        let binCount = magnitudes.count
        let frequencyResolution = sampleRate / Float(fftSize)

        for bandIndex in 0..<16 {
            let lowFreq = bandFrequencies[bandIndex]
            let highFreq = bandFrequencies[bandIndex + 1]

            // Convert frequencies to bin indices
            let lowBin = Int(lowFreq / frequencyResolution)
            let highBin = Int(highFreq / frequencyResolution)

            // Ensure we have valid bin range
            let startBin = max(1, min(lowBin, binCount - 1))
            let endBin = max(startBin + 1, min(highBin, binCount))

            // Average magnitudes in this band
            var sum: Float = 0
            var count = 0

            for bin in startBin..<endBin {
                sum += magnitudes[bin]
                count += 1
            }

            let avgMagnitude = count > 0 ? sum / Float(count) : 0

            // Convert to dB (will be negative for magnitudes < 1.0)
            let db = 20 * log10(max(avgMagnitude, 1e-10))

            // Clamp dB value to configurable range
            let clampedDb = max(minDB, min(maxDB, db))

            // Normalize to 0.0-1.0
            let normalized = (clampedDb - minDB) / (maxDB - minDB)

            bands[bandIndex] = normalized
        }

        return bands
    }
}
