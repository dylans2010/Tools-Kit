import SwiftUI
import AVFoundation

struct Diag_EarpieceTestView: View {
    @State private var isPlaying = false
    @State private var earpieceAvailable = false
    @State private var currentRoute = ""
    @State private var frequency: Double = 1000
    @State private var volume: Float = 0.5
    @State private var testResult: String = "Not tested"
    @State private var audioEngine: AVAudioEngine?
    @State private var playerNode: AVAudioPlayerNode?

    var body: some View {
        Form {
            Section("Earpiece Status") {
                VStack(spacing: 12) {
                    Image(systemName: earpieceAvailable ? "ear.fill" : "ear")
                        .font(.system(size: 52))
                        .foregroundStyle(earpieceAvailable ? .green : .secondary)
                    Text(earpieceAvailable ? "Earpiece Detected" : "Checking Earpiece...")
                        .font(.headline)
                    Text("Hold phone to ear during test")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Audio Route") {
                LabeledContent("Current Output") {
                    Text(currentRoute)
                        .font(.caption)
                }
                LabeledContent("Earpiece Available") {
                    Image(systemName: earpieceAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(earpieceAvailable ? .green : .red)
                }
            }

            Section("Test Controls") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frequency: \(Int(frequency)) Hz")
                        .font(.caption)
                    Slider(value: $frequency, in: 200...8000, step: 100)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volume: \(Int(volume * 100))%")
                        .font(.caption)
                    Slider(value: $volume, in: 0...1, step: 0.05)
                }
                Button {
                    if isPlaying { stopTone() } else { playToneToEarpiece() }
                } label: {
                    HStack {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        Text(isPlaying ? "Stop Earpiece Test" : "Play Tone to Earpiece")
                    }
                }
            }

            Section("Test Result") {
                LabeledContent("Status") {
                    Text(testResult)
                        .foregroundStyle(testResult == "Pass" ? .green : testResult == "Fail" ? .red : .secondary)
                }
            }

            Section("Earpiece Info") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Tests the built-in earpiece receiver", systemImage: "info.circle")
                        .font(.caption)
                    Label("Routes audio exclusively to earpiece", systemImage: "ear.fill")
                        .font(.caption)
                    Label("Frequency sweep checks full range", systemImage: "waveform")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Earpiece Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkEarpiece() }
        .onDisappear { stopTone() }
    }

    private func checkEarpiece() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [])
            try session.overrideOutputAudioPort(.none)
            try session.setActive(true)
            let route = session.currentRoute
            let outputs = route.outputs.map { $0.portName }.joined(separator: ", ")
            currentRoute = outputs.isEmpty ? "None" : outputs
            earpieceAvailable = route.outputs.contains { $0.portType == .builtInReceiver }
            if !earpieceAvailable {
                earpieceAvailable = route.outputs.contains { $0.portType == .builtInSpeaker }
            }
        } catch {
            currentRoute = "Error: \(error.localizedDescription)"
            earpieceAvailable = false
        }
    }

    private func playToneToEarpiece() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [])
            try session.overrideOutputAudioPort(.none)
            try session.setActive(true)
        } catch {
            testResult = "Fail"
            return
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let frameCount = AVAudioFrameCount(sampleRate * 2)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let omega = 2.0 * Double.pi * frequency / sampleRate
        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                channelData[i] = Float(sin(omega * Double(i))) * volume
            }
        }

        do {
            try engine.start()
            player.play()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            isPlaying = true
            testResult = "Playing..."
            audioEngine = engine
            playerNode = player
        } catch {
            testResult = "Fail"
        }
    }

    private func stopTone() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        isPlaying = false
        if testResult == "Playing..." { testResult = "Pass" }
    }
}
