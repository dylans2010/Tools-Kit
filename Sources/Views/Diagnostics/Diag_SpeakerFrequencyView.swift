import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_SpeakerFrequencyView: View {
    @State private var audioEngine = AVAudioEngine()
    @State private var toneNode: AVAudioSourceNode?
    @State private var isPlaying = false
    @State private var currentFrequency: Double = 440
    @State private var volume: Float = 0.5
    @State private var sweepActive = false
    @State private var sweepFrequency: Double = 20
    @State private var sweepTimer: Timer?
    @State private var detectedIssues: [String] = []
    @State private var statusText = "Ready"
    @State private var testedRanges: Set<String> = []

    private let presetFrequencies: [(String, Double)] = [
        ("Sub-Bass (20 Hz)", 20),
        ("Bass (60 Hz)", 60),
        ("Low-Mid (250 Hz)", 250),
        ("Mid (1 kHz)", 1000),
        ("Upper-Mid (4 kHz)", 4000),
        ("Presence (8 kHz)", 8000),
        ("Brilliance (12 kHz)", 12000),
        ("High (16 kHz)", 16000),
        ("Ultra-High (20 kHz)", 20000),
    ]

    var body: some View {
        Form {
            Section("Frequency Generator") {
                VStack(spacing: 12) {
                    Text(String(format: "%.0f Hz", currentFrequency))
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundStyle(.blue)

                    Text(frequencyLabel(currentFrequency))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Slider(value: $currentFrequency, in: 20...20000, step: 1) {
                        Text("Frequency")
                    }
                    .onChange(of: currentFrequency) { _, newValue in
                        if isPlaying { updateToneFrequency(newValue) }
                    }
                }
                .padding(.vertical, 8)

                VStack(alignment: .leading) {
                    Text("Volume: \(Int(volume * 100))%")
                        .font(.subheadline)
                    Slider(value: $volume, in: 0...1, step: 0.05)
                        .tint(.orange)
                }

                HStack {
                    Button {
                        if isPlaying { stopTone() } else { playTone(frequency: currentFrequency) }
                    } label: {
                        HStack {
                            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            Text(isPlaying ? "Stop" : "Play Tone")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Preset Frequencies") {
                ForEach(presetFrequencies, id: \.1) { name, freq in
                    Button {
                        currentFrequency = freq
                        playTone(frequency: freq)
                    } label: {
                        HStack {
                            Text(name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if testedRanges.contains(name) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            Section("Frequency Sweep") {
                VStack(spacing: 8) {
                    if sweepActive {
                        Text(String(format: "Sweeping: %.0f Hz", sweepFrequency))
                            .font(.subheadline.monospacedDigit())
                        ProgressView(value: (sweepFrequency - 20) / 19980)
                            .tint(.purple)
                    }
                }

                Button {
                    if sweepActive { stopSweep() } else { startSweep() }
                } label: {
                    HStack {
                        Image(systemName: sweepActive ? "stop.circle.fill" : "waveform.path.ecg")
                        Text(sweepActive ? "Stop Sweep" : "Start 20Hz → 20kHz Sweep")
                    }
                }
            }

            if !detectedIssues.isEmpty {
                Section("Detected Issues") {
                    ForEach(detectedIssues, id: \.self) { issue in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(issue)
                                .font(.caption)
                        }
                    }
                }
            }

            Section {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Use headphones for accurate frequency testing. Built-in speakers may not reproduce very low (<100 Hz) or very high (>16 kHz) frequencies.")
            }
        }
        .navigationTitle("Speaker Frequency")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopTone()
            stopSweep()
        }
    }

    private func frequencyLabel(_ freq: Double) -> String {
        if freq < 60 { return "Sub-Bass" }
        if freq < 250 { return "Bass" }
        if freq < 500 { return "Low-Mid" }
        if freq < 2000 { return "Mid" }
        if freq < 4000 { return "Upper-Mid" }
        if freq < 8000 { return "Presence" }
        if freq < 12000 { return "Brilliance" }
        return "Air/Ultra-High"
    }

    private func playTone(frequency: Double) {
        stopTone()

        let sampleRate: Double = 44100
        var phase: Double = 0
        let phaseIncrement = (2.0 * .pi * frequency) / sampleRate

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let sample = Float(sin(phase)) * self.volume
                phase += phaseIncrement
                if phase >= 2.0 * .pi { phase -= 2.0 * .pi }
                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample
                }
            }
            return noErr
        }

        toneNode = sourceNode
        let mainMixer = audioEngine.mainMixerNode
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer, format: mainMixer.outputFormat(forBus: 0))

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .measurement)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
            isPlaying = true
            statusText = "Playing \(String(format: "%.0f", frequency)) Hz tone"

            // Track tested range
            for (name, freq) in presetFrequencies {
                if abs(frequency - freq) < 50 {
                    testedRanges.insert(name)
                }
            }
        } catch {
            statusText = "Error: \(error.localizedDescription)"
        }
    }

    private func updateToneFrequency(_ frequency: Double) {
        if isPlaying {
            stopTone()
            playTone(frequency: frequency)
        }
    }

    private func stopTone() {
        audioEngine.stop()
        if let node = toneNode {
            audioEngine.detach(node)
            toneNode = nil
        }
        isPlaying = false
    }

    private func startSweep() {
        sweepActive = true
        sweepFrequency = 20
        playTone(frequency: sweepFrequency)

        sweepTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            sweepFrequency *= 1.01
            if sweepFrequency >= 20000 {
                stopSweep()
                statusText = "Sweep complete: 20 Hz → 20 kHz"
                return
            }
            stopTone()
            playTone(frequency: sweepFrequency)
        }
    }

    private func stopSweep() {
        sweepTimer?.invalidate()
        sweepTimer = nil
        sweepActive = false
        stopTone()
    }
}
