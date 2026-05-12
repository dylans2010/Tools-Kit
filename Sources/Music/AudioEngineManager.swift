import Foundation
import AVFoundation
import Combine

// MARK: - EQ Preset

struct EQPreset: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var gains: [Float] // 8 bands, dB

    init(id: UUID = UUID(), name: String, gains: [Float]) {
        self.id = id
        self.name = name
        self.gains = gains
    }

    static let flat       = EQPreset(name: "Flat",       gains: [0, 0,  0,  0,  0,  0,  0,  0])
    static let bassBoost  = EQPreset(name: "Bass Boost",  gains: [6, 4,  2,  0,  0,  0,  0,  0])
    static let treble     = EQPreset(name: "Treble Boost",gains: [0, 0,  0,  0,  0,  2,  4,  6])
    static let vocal      = EQPreset(name: "Vocal",       gains: [-2,-1, 0,  3,  4,  3,  1,  0])
    static let rock       = EQPreset(name: "Rock",        gains: [4, 3, -1, -1,  1,  3,  4,  4])
    static let jazz       = EQPreset(name: "Jazz",        gains: [3, 2,  0,  2, -2, -2,  0,  2])
    static let classical  = EQPreset(name: "Classical",   gains: [5, 3, -2,  0,  0,  0,  2,  4])
    static let hipHop     = EQPreset(name: "Hip-Hop",     gains: [5, 4,  2, -1, -1,  1,  1,  2])
    static let pop        = EQPreset(name: "Pop",         gains: [-1,0,  2,  3,  2,  0, -1, -1])
    static let electronic = EQPreset(name: "Electronic",  gains: [5, 3,  0, -2,  0,  1,  3,  4])

    static let builtIn: [EQPreset] = [.flat, .bassBoost, .treble, .vocal, .rock, .jazz, .classical, .hipHop, .pop, .electronic]
}

// MARK: - Audio Output Mode

enum AudioOutputMode: String, CaseIterable, Codable, Sendable {
    case stereo = "Stereo"
    case mono   = "Mono"
}

// MARK: - AudioEngineManager

final class AudioEngineManager: ObservableObject {
    static let shared = AudioEngineManager()

    // MARK: Published settings
    @Published var gains: [Float] = Array(repeating: 0, count: 8)
    @Published var equalizerEnabled: Bool = false
    @Published var crossfadeEnabled: Bool = false
    @Published var crossfadeDuration: Double = 3.0
    @Published var playbackRate: Float = 1.0
    @Published var outputMode: AudioOutputMode = .stereo

    // MARK: Band metadata
    let bandFrequencies: [Float] = [60, 170, 310, 600, 1_000, 3_000, 6_000, 14_000]
    let bandNames = ["Sub Bass", "Bass", "Low Mid", "Mid", "Upper Mid", "Presence", "Brilliance", "Treble"]

    // MARK: Callbacks
    var onTrackFinished: (() -> Void)?
    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onPlaybackFailed: (() -> Void)?

    // MARK: Private – engine graph
    private let engine = AVAudioEngine()
    private var nodes: [AVAudioPlayerNode] = [AVAudioPlayerNode(), AVAudioPlayerNode()]
    private var activeIndex: Int = 0
    private let playerMixer = AVAudioMixerNode()
    private let eqNode: AVAudioUnitEQ
    private let timePitch = AVAudioUnitTimePitch()

    // MARK: Private – state
    private var currentFile: AVAudioFile?
    private var activeStartFrame: AVAudioFramePosition = 0
    private var totalFrames: Int64 = 0
    private var sampleRate: Double = 44_100
    private var crossfadeTimer: Timer?
    private var fadingStepTimer: Timer?
    private var positionTimer: Timer?
    private var isEngineReady = false

    // MARK: Persistence keys
    private let kGains            = "audio.eq.gains"
    private let kEQEnabled        = "audio.eq.enabled"
    private let kCrossfadeEnabled = "audio.crossfade.enabled"
    private let kCrossfadeDur     = "audio.crossfade.duration"
    private let kRate             = "audio.rate"
    private let kOutputMode       = "audio.outputMode"

    // MARK: Private vars
    private var activeNode: AVAudioPlayerNode { nodes[activeIndex] }
    private var fadeNode:   AVAudioPlayerNode { nodes[1 - activeIndex] }

    // MARK: - Init

    private init() {
        eqNode = AVAudioUnitEQ(numberOfBands: 8)
        loadPersistedSettings()
        setupEngineGraph()
    }

    // MARK: - Engine Setup

    private func setupEngineGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!

        for node in nodes { engine.attach(node) }
        engine.attach(playerMixer)
        engine.attach(eqNode)
        engine.attach(timePitch)

        for node in nodes {
            engine.connect(node, to: playerMixer, format: format)
        }
        engine.connect(playerMixer, to: eqNode, format: format)
        engine.connect(eqNode, to: timePitch, format: format)
        engine.connect(timePitch, to: engine.mainMixerNode, format: format)

        configureEQBands()
        applyEQ()
        applyRate()

        startEngine()
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
            isEngineReady = true
        } catch {
            print("AudioEngineManager: engine failed to start – \(error)")
        }
    }

    private func configureEQBands() {
        let filterTypes: [AVAudioUnitEQFilterType] = [
            .lowShelf, .parametric, .parametric, .parametric,
            .parametric, .parametric, .parametric, .highShelf
        ]
        for (i, band) in eqNode.bands.enumerated() {
            band.frequency  = bandFrequencies[i]
            band.bandwidth  = 1.0
            band.filterType = filterTypes[i]
            band.gain       = equalizerEnabled ? gains[i] : 0
            band.bypass     = false
        }
    }

    // MARK: - Playback

    func play(url: URL, startTime: TimeInterval = 0) {
        stopCurrent()

        guard let file = try? AVAudioFile(forReading: url) else {
            print("AudioEngineManager: cannot open \(url.lastPathComponent)")
            DispatchQueue.main.async { self.onPlaybackFailed?() }
            return
        }

        currentFile    = file
        sampleRate     = file.processingFormat.sampleRate
        totalFrames    = file.length
        activeStartFrame = AVAudioFramePosition(startTime * sampleRate)

        scheduleSegment(from: activeStartFrame, on: activeNode, file: file)
        activeNode.play()
        startPositionTimer()
    }

    func pause() {
        activeNode.pause()
        fadeNode.pause()
        stopPositionTimer()
    }

    func resume() {
        if !engine.isRunning { startEngine() }
        activeNode.play()
        startPositionTimer()
    }

    func stop() {
        stopCurrent()
        currentFile = nil
        totalFrames = 0
    }

    func seek(to time: TimeInterval) {
        guard let file = currentFile else { return }
        let wasPlaying = activeNode.isPlaying
        activeNode.stop()

        let frame = clamp(AVAudioFramePosition(time * sampleRate), min: 0, max: file.length - 1)
        activeStartFrame = frame

        scheduleSegment(from: frame, on: activeNode, file: file)
        if wasPlaying { activeNode.play() }
    }

    var currentTime: TimeInterval {
        guard let nodeTime   = activeNode.lastRenderTime,
              let playerTime = activeNode.playerTime(forNodeTime: nodeTime),
              playerTime.sampleTime >= 0
        else { return Double(activeStartFrame) / max(1, sampleRate) }

        let elapsed = Double(playerTime.sampleTime) / sampleRate
        let start   = Double(activeStartFrame) / sampleRate
        return max(0, start + elapsed)
    }

    var totalDuration: TimeInterval { Double(totalFrames) / max(1, sampleRate) }

    var isActuallyPlaying: Bool { nodes[activeIndex].isPlaying }

    // MARK: - Crossfade

    /// Call after loading a new song to pre-schedule a crossfade.
    func scheduleCrossfadeIfNeeded(nextURL: URL, trackDuration: TimeInterval) {
        crossfadeTimer?.invalidate()
        guard crossfadeEnabled, crossfadeDuration > 0 else { return }

        let delay = max(0, trackDuration - crossfadeDuration - currentTime)
        crossfadeTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.beginCrossfadeTo(nextURL)
        }
    }

    private func beginCrossfadeTo(_ url: URL) {
        guard let file = try? AVAudioFile(forReading: url) else { return }

        let incoming = fadeNode
        incoming.volume = 0

        scheduleSegment(from: 0, on: incoming, file: file, completionHandler: { [weak self] in
            DispatchQueue.main.async { self?.onTrackFinished?() }
        })
        incoming.play()

        let steps      = 30
        let stepDur    = crossfadeDuration / Double(steps)
        var step       = 0
        let outgoing   = activeNode

        fadingStepTimer?.invalidate()
        fadingStepTimer = Timer.scheduledTimer(withTimeInterval: stepDur, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            let progress = Float(step) / Float(steps)
            outgoing.volume = 1 - progress
            incoming.volume = progress
            if step >= steps {
                timer.invalidate()
                self.fadingStepTimer = nil
                outgoing.stop()
                outgoing.volume = 1
                self.currentFile       = file
                self.sampleRate        = file.processingFormat.sampleRate
                self.totalFrames       = file.length
                self.activeStartFrame  = 0
                self.activeIndex       = 1 - self.activeIndex  // swap active/fade roles
            }
        }
    }

    // MARK: - EQ

    func applyEQ() {
        let bands = eqNode.bands
        for (i, band) in bands.enumerated() {
            band.gain = equalizerEnabled ? gains[i] : 0
        }
    }

    func applyPreset(_ preset: EQPreset) {
        gains = preset.gains
        applyEQ()
        saveSettings()
    }

    func setGain(_ gain: Float, forBand index: Int) {
        guard index < gains.count else { return }
        gains[index] = gain
        eqNode.bands[index].gain = equalizerEnabled ? gain : 0
        saveSettings()
    }

    func setEqualizerEnabled(_ enabled: Bool) {
        equalizerEnabled = enabled
        applyEQ()
        saveSettings()
    }

    // MARK: - Rate

    func applyRate() {
        timePitch.rate = max(0.5, min(2.0, playbackRate))
    }

    // MARK: - Settings

    func saveSettings() {
        let d = UserDefaults.standard
        d.set(gains,              forKey: kGains)
        d.set(equalizerEnabled,   forKey: kEQEnabled)
        d.set(crossfadeEnabled,   forKey: kCrossfadeEnabled)
        d.set(crossfadeDuration,  forKey: kCrossfadeDur)
        d.set(playbackRate,       forKey: kRate)
        d.set(outputMode.rawValue,forKey: kOutputMode)
    }

    private func loadPersistedSettings() {
        let d = UserDefaults.standard
        if let arr = d.array(forKey: kGains) as? [Float], arr.count == 8 { gains = arr }
        equalizerEnabled  = d.bool(forKey: kEQEnabled)
        crossfadeEnabled  = d.bool(forKey: kCrossfadeEnabled)
        let dur = d.double(forKey: kCrossfadeDur); crossfadeDuration = dur > 0 ? dur : 3.0
        let rt  = d.float(forKey: kRate);          playbackRate      = rt  > 0 ? rt  : 1.0
        if let raw = d.string(forKey: kOutputMode) { outputMode = AudioOutputMode(rawValue: raw) ?? .stereo }
    }

    // MARK: - Private Helpers

    private func scheduleSegment(
        from startFrame: AVAudioFramePosition,
        on node: AVAudioPlayerNode,
        file: AVAudioFile,
        completionHandler: (() -> Void)? = nil
    ) {
        let remaining = AVAudioFrameCount(max(0, file.length - startFrame))
        guard remaining > 0 else { return }

        node.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: remaining,
            at: nil
        ) { [weak self] in
            DispatchQueue.main.async {
                completionHandler?() ?? self?.onTrackFinished?()
            }
        }
    }

    private func stopCurrent() {
        crossfadeTimer?.invalidate()
        crossfadeTimer = nil
        fadingStepTimer?.invalidate()
        fadingStepTimer = nil
        for node in nodes { node.stop(); node.volume = 1 }
        stopPositionTimer()
    }

    private func startPositionTimer() {
        stopPositionTimer()
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.onTimeUpdate?(self.currentTime)
        }
    }

    private func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    private func clamp(_ value: AVAudioFramePosition, min: AVAudioFramePosition, max: AVAudioFramePosition) -> AVAudioFramePosition {
        Swift.max(min, Swift.min(max, value))
    }
}
