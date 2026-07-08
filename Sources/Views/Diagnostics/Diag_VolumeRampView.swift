import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_VolumeRampView: View {
    @State private var isPlaying = false
    @State private var currentVolume: Float = 0.0
    @State private var rampDuration: Double = 5.0
    @State private var audioEngine: AVAudioEngine?
    @State private var playerNode: AVAudioPlayerNode?
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Volume Ramp") {
                VStack(spacing: 16) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                        .symbolEffect(.variableColor.iterative, isActive: isPlaying)

                    ProgressView(value: Double(currentVolume))
                        .progressViewStyle(.linear)
                        .tint(.blue)
                        .scaleEffect(y: 3)

                    Text("\(Int(currentVolume * 100))%")
                        .font(.title.monospacedDigit().bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ramp Duration: \(rampDuration, specifier: "%.1f")s")
                        .font(.subheadline)
                    Slider(value: $rampDuration, in: 2...15, step: 0.5)
                }
            }

            Section {
                Button {
                    if isPlaying { stopRamp() } else { startRamp() }
                } label: {
                    HStack {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        Text(isPlaying ? "Stop Ramp" : "Start Volume Ramp")
                    }
                }
            }

            Section {
                Text("This test gradually increases audio volume from silent to maximum over the selected duration. Use headphones for the best experience.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Volume Ramp")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopRamp() }
    }

    private func startRamp() {
        currentVolume = 0.0
        isPlaying = true

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        player.volume = 0.0

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let sampleRate = Float(format.sampleRate)
        let frameCount = AVAudioFrameCount(sampleRate * 30.0)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        if let data = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                data[i] = sin(2.0 * .pi * 440.0 * Float(i) / sampleRate) * 0.5
            }
        }

        do {
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            audioEngine = engine
            playerNode = player

            let interval = 0.05
            let steps = rampDuration / interval
            var step = 0.0
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
                step += 1
                let progress = Float(min(step / steps, 1.0))
                currentVolume = progress
                player.volume = progress
                if progress >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { stopRamp() }
                }
            }
        } catch {
            isPlaying = false
        }
    }

    private func stopRamp() {
        timer?.invalidate()
        timer = nil
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
        currentVolume = 0.0
    }
}
