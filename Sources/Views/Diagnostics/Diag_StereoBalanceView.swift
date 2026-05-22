import SwiftUI
import AVFoundation

struct Diag_StereoBalanceView: View {
    @State private var balance: Float = 0.0
    @State private var isPlaying = false
    @State private var audioEngine: AVAudioEngine?
    @State private var playerNode: AVAudioPlayerNode?

    var body: some View {
        Form {
            Section("Stereo Balance Control") {
                VStack(spacing: 16) {
                    HStack {
                        Text("L")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("Center")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("R")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }

                    Slider(value: $balance, in: -1...1, step: 0.05) {
                        Text("Balance")
                    }
                    .onChange(of: balance) { _, newVal in
                        playerNode?.pan = newVal
                    }

                    Text(balanceLabel)
                        .font(.title3.monospacedDigit().bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            Section("Visualization") {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: max(4, CGFloat((1.0 - balance) / 2.0) * 150), height: 40)
                        .animation(.spring(response: 0.2), value: balance)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: max(4, CGFloat((1.0 + balance) / 2.0) * 150), height: 40)
                        .animation(.spring(response: 0.2), value: balance)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Section {
                Button {
                    if isPlaying { stopAudio() } else { startTone() }
                } label: {
                    HStack {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        Text(isPlaying ? "Stop Tone" : "Play Test Tone")
                    }
                }

                Button("Reset to Center") {
                    balance = 0.0
                    playerNode?.pan = 0.0
                }
            }
        }
        .navigationTitle("Stereo Balance")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopAudio() }
    }

    private var balanceLabel: String {
        if balance < -0.05 { return "Left \(Int(abs(balance) * 100))%" }
        if balance > 0.05 { return "Right \(Int(balance * 100))%" }
        return "Center"
    }

    private func startTone() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        player.pan = balance

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let sampleRate = Float(format.sampleRate)
        let duration: Float = 30.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        if let data = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                data[i] = sin(2.0 * .pi * 440.0 * Float(i) / sampleRate) * 0.4
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

    private func stopAudio() {
        playerNode?.stop()
        audioEngine?.stop()
        isPlaying = false
    }
}
