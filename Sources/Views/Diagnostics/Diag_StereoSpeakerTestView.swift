import SwiftUI
import AVFoundation

struct Diag_StereoSpeakerTestView: View {
    @State private var isPlaying = false
    @State private var playingSpeaker: String = "None"
    @State private var details: [(String, String)] = []
    @State private var leftPassed = false
    @State private var rightPassed = false
    @State private var audioEngine: AVAudioEngine?
    @State private var playerNode: AVAudioPlayerNode?

    var body: some View {
        Form {
            Section("Stereo Speakers") {
                VStack(spacing: 12) {
                    HStack(spacing: 32) {
                        VStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(leftPassed ? .green : playingSpeaker == "Left" ? .blue : .secondary)
                            Text("Left")
                                .font(.caption)
                        }
                        VStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(rightPassed ? .green : playingSpeaker == "Right" ? .blue : .secondary)
                            Text("Right")
                                .font(.caption)
                        }
                    }
                    Text("Test each stereo speaker independently")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Audio Output") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Speaker Tests") {
                Button {
                    playTone(pan: -1.0, label: "Left")
                } label: {
                    HStack {
                        Image(systemName: "speaker.wave.1.fill")
                        Text("Play Left Speaker")
                        Spacer()
                        if leftPassed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .disabled(isPlaying)

                Button {
                    playTone(pan: 1.0, label: "Right")
                } label: {
                    HStack {
                        Image(systemName: "speaker.wave.1.fill")
                        Text("Play Right Speaker")
                        Spacer()
                        if rightPassed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .disabled(isPlaying)

                Button {
                    playTone(pan: 0.0, label: "Both")
                } label: {
                    HStack {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Play Both Speakers")
                    }
                }
                .disabled(isPlaying)

                if isPlaying {
                    Button {
                        stopTone()
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop")
                        }
                        .foregroundStyle(.red)
                    }
                }
            }

            Section("Results") {
                LabeledContent("Left Speaker") {
                    Text(leftPassed ? "Pass" : "Not tested")
                        .foregroundStyle(leftPassed ? .green : .secondary)
                }
                LabeledContent("Right Speaker") {
                    Text(rightPassed ? "Pass" : "Not tested")
                        .foregroundStyle(rightPassed ? .green : .secondary)
                }
                LabeledContent("Stereo") {
                    Text(leftPassed && rightPassed ? "Pass" : "Incomplete")
                        .foregroundStyle(leftPassed && rightPassed ? .green : .secondary)
                }
            }

            Section {
                Button {
                    leftPassed = false
                    rightPassed = false
                } label: {
                    HStack { Image(systemName: "arrow.counterclockwise"); Text("Reset Results") }
                }
            }
        }
        .navigationTitle("Stereo Speaker Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkAudio() }
        .onDisappear { stopTone() }
    }

    private func checkAudio() {
        let session = AVAudioSession.sharedInstance()
        var info: [(String, String)] = []
        let route = session.currentRoute
        let outputs = route.outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", ")
        info.append(("Output Route", outputs.isEmpty ? "None" : outputs))
        info.append(("Sample Rate", String(format: "%.0f Hz", session.sampleRate)))
        info.append(("Output Channels", "\(session.outputNumberOfChannels)"))
        info.append(("Output Volume", String(format: "%.0f%%", session.outputVolume * 100)))
        details = info
    }

    private func playTone(pan: Float, label: String) {
        stopTone()

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.pan = pan

        let frameCount = AVAudioFrameCount(sampleRate * 2)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let freq = 440.0
        let omega = 2.0 * Double.pi * freq / sampleRate
        if let left = buffer.floatChannelData?[0], let right = buffer.floatChannelData?[1] {
            for i in 0..<Int(frameCount) {
                let sample = Float(sin(omega * Double(i))) * 0.5
                left[i] = sample
                right[i] = sample
            }
        }

        do {
            try engine.start()
            player.play()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            isPlaying = true
            playingSpeaker = label
            audioEngine = engine
            playerNode = player

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                stopTone()
                if label == "Left" { leftPassed = true }
                if label == "Right" { rightPassed = true }
                if label == "Both" { leftPassed = true; rightPassed = true }
            }
        } catch {}
    }

    private func stopTone() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        isPlaying = false
        playingSpeaker = "None"
    }
}
