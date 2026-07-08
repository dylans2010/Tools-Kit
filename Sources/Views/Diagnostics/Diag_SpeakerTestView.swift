import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_SpeakerTestView: View {
    @State private var isPlayingLeft = false
    @State private var isPlayingRight = false
    @State private var audioEngine: AVAudioEngine?
    @State private var playerNode: AVAudioPlayerNode?

    var body: some View {
        Form {
            Section("Speaker Channel Test") {
                VStack(spacing: 20) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                        .padding(.vertical, 10)

                    Text("Test each speaker channel independently to verify stereo output is working correctly.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }

            Section("Left Channel") {
                Button {
                    playTone(pan: -1.0, isLeft: true)
                } label: {
                    HStack {
                        Image(systemName: isPlayingLeft ? "speaker.wave.3.fill" : "speaker.fill")
                            .foregroundStyle(.blue)
                        Text(isPlayingLeft ? "Playing Left..." : "Test Left Speaker")
                        Spacer()
                        if isPlayingLeft {
                            ProgressView()
                        }
                    }
                }
                .disabled(isPlayingLeft || isPlayingRight)
            }

            Section("Right Channel") {
                Button {
                    playTone(pan: 1.0, isLeft: false)
                } label: {
                    HStack {
                        Image(systemName: isPlayingRight ? "speaker.wave.3.fill" : "speaker.fill")
                            .foregroundStyle(.orange)
                        Text(isPlayingRight ? "Playing Right..." : "Test Right Speaker")
                        Spacer()
                        if isPlayingRight {
                            ProgressView()
                        }
                    }
                }
                .disabled(isPlayingLeft || isPlayingRight)
            }

            Section("Both Channels") {
                Button {
                    playTone(pan: 0.0, isLeft: true)
                } label: {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(.green)
                        Text("Test Both Speakers")
                    }
                }
                .disabled(isPlayingLeft || isPlayingRight)
            }
        }
        .navigationTitle("Speaker L/R Test")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopAudio() }
    }

    private func playTone(pan: Float, isLeft: Bool) {
        if isLeft { isPlayingLeft = true } else { isPlayingRight = true }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        player.pan = pan

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let sampleRate = Float(format.sampleRate)
        let duration: Float = 1.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let frequency: Float = 440.0
        if let data = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                data[i] = sin(2.0 * .pi * frequency * Float(i) / sampleRate) * 0.5
            }
        }

        do {
            try engine.start()
            player.scheduleBuffer(buffer) {
                DispatchQueue.main.async {
                    isPlayingLeft = false
                    isPlayingRight = false
                    engine.stop()
                }
            }
            player.play()
            audioEngine = engine
            playerNode = player
        } catch {
            isPlayingLeft = false
            isPlayingRight = false
        }
    }

    private func stopAudio() {
        playerNode?.stop()
        audioEngine?.stop()
        isPlayingLeft = false
        isPlayingRight = false
    }
}
