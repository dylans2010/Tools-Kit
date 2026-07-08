import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_DistortionDetectionView: View {
    @State private var isPlaying = false
    @State private var frequency: Double = 440
    @State private var volume: Double = 0.5
    @State private var audioEngine: AVAudioEngine?
    @State private var playerNode: AVAudioPlayerNode?

    private let frequencies: [(String, Double)] = [
        ("Low (100 Hz)", 100), ("Mid-Low (250 Hz)", 250),
        ("Mid (440 Hz)", 440), ("Mid-High (1 kHz)", 1000),
        ("High (4 kHz)", 4000), ("Very High (8 kHz)", 8000)
    ]

    var body: some View {
        Form {
            Section("Distortion Test") {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)

                    Text("Play pure tones at various frequencies and volumes.\nListen for buzzing, rattling, or distortion.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            Section("Frequency") {
                ForEach(frequencies, id: \.1) { name, freq in
                    Button {
                        frequency = freq
                        if isPlaying { restartTone() }
                    } label: {
                        HStack {
                            Text(name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if frequency == freq {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section("Volume") {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $volume, in: 0.1...1.0, step: 0.05) {
                        Text("Volume")
                    }
                    .onChange(of: volume) { _, _ in
                        playerNode?.volume = Float(volume)
                    }
                    Text("\(Int(volume * 100))%")
                        .font(.subheadline.monospacedDigit())
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            Section {
                Button {
                    if isPlaying { stopTone() } else { startTone() }
                } label: {
                    HStack {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        Text(isPlaying ? "Stop" : "Play Tone")
                    }
                }
            }
        }
        .navigationTitle("Distortion Detection")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopTone() }
    }

    private func startTone() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        player.volume = Float(volume)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(sampleRate * 30.0)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let freq = Float(frequency)
        if let data = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                data[i] = sin(2.0 * .pi * freq * Float(i) / sampleRate) * 0.5
            }
        }

        do {
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            audioEngine = engine
            playerNode = player
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    private func stopTone() {
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
    }

    private func restartTone() {
        stopTone()
        startTone()
    }
}
