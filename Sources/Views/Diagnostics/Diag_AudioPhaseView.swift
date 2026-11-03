import SwiftUI
import AVFoundation

/// Real stereo routing test. The previous version hardcoded
/// "Correlation 0.98 / Phase Offset 2.1°" — a phase correlation cannot be
/// measured from the phone's speaker and mic inside an app sandbox, so
/// those numbers were invented. This version reports the live audio
/// session routing and plays a real tone panned to one channel at a time,
/// so the user can hear (and confirm) which speaker/channel is active.
struct Diag_AudioPhaseView: View {
    @State private var engine: AVAudioEngine?
    @State private var player: AVAudioPlayerNode?
    @State private var playing: String?
    @State private var routeRows: [(String, String)] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Speaker Phase Correlation")
                .font(.headline)

            HStack(spacing: 40) {
                VStack {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.largeTitle)
                    Text("Left")
                }
                Image(systemName: "arrow.left.and.right")
                    .font(.title)
                    .foregroundStyle(.green)
                VStack {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.largeTitle)
                    Text("Right")
                }
            }
            .padding()

            List {
                Section("Live Audio Route") {
                    ForEach(routeRows, id: \.0) { row in
                        LabeledContent(row.0) { Text(row.1).font(.caption) }
                    }
                }
                Section("Channel Test") {
                    Button("Play Left Channel Only") { playTone(pan: -1, label: "Left") }
                    Button("Play Right Channel Only") { playTone(pan: 1, label: "Right") }
                    Button("Play Both Channels") { playTone(pan: 0, label: "Both") }
                    if let playing {
                        Text("Playing: \(playing) — confirm you hear it on that side.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Stop Tone", role: .destructive) { stopTone() }
                }
                Section {
                    Text("No correlation or phase-offset number is shown here on purpose: iOS does not give an app a loopback measurement of its own speaker output, so any such number would be invented. This test verifies routing with a real panned tone instead.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Audio Phase Test")
        .onAppear { loadRoute() }
        .onDisappear { stopTone() }
    }

    private func loadRoute() {
        let session = AVAudioSession.sharedInstance()
        var rows: [(String, String)] = []
        rows.append(("Output Channels", "\(session.outputNumberOfChannels)"))
        rows.append(("Input Channels", "\(session.inputNumberOfChannels)"))
        rows.append(("Sample Rate", String(format: "%.0f Hz", session.sampleRate)))
        for output in session.currentRoute.outputs {
            rows.append(("Output: \(output.portName)", output.portType.rawValue))
        }
        if session.currentRoute.outputs.isEmpty {
            rows.append(("Output", "None"))
        }
        routeRows = rows
    }

    private func playTone(pan: Float, label: String) {
        stopTone()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Tone playback will fail below if the session cannot start; do not invent a result.
        }
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        let frameCount = AVAudioFrameCount(44100)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        for channel in 0..<2 {
            let data = buffer.floatChannelData![channel]
            for i in 0..<Int(frameCount) {
                data[i] = Float(sin(2.0 * Double.pi * 880.0 * Double(i) / 44100.0)) * 0.25
            }
        }
        player.pan = pan
        do {
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            self.engine = engine
            self.player = player
            playing = label
        } catch {
            playing = nil
        }
    }

    private func stopTone() {
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
        playing = nil
    }
}
