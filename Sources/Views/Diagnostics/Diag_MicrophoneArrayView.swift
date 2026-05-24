import SwiftUI
import AVFoundation

struct Diag_MicrophoneArrayView: View {
    @State private var details: [(String, String)] = []
    @State private var micCount = 0

    var body: some View {
        Form {
            Section("Microphone Array") {
                VStack(spacing: 12) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(micCount > 0 ? .red : .secondary)
                    Text("\(micCount) Microphone\(micCount == 1 ? "" : "s") Detected")
                        .font(.headline)
                    Text("Tests all built-in microphones for beamforming and noise cancellation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Microphone Details") {
                ForEach(details, id: \.0) { d in
                    LabeledContent(d.0) { Text(d.1).font(.caption) }
                }
            }

            Section("Microphone Positions") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Bottom microphone (primary calls)", systemImage: "mic.fill").font(.caption)
                    Label("Front microphone (FaceTime, Siri)", systemImage: "mic.fill").font(.caption)
                    Label("Rear microphone (video recording)", systemImage: "mic.fill").font(.caption)
                    Label("Beamforming array for directional audio", systemImage: "mic.badge.plus").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section("Audio Features") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Voice Isolation mode", systemImage: "person.wave.2.fill").font(.caption)
                    Label("Wide Spectrum mode", systemImage: "waveform").font(.caption)
                    Label("Wind noise reduction", systemImage: "wind").font(.caption)
                    Label("Studio-quality microphone (iPhone 14+)", systemImage: "mic.square.fill").font(.caption)
                    Label("Spatial Audio recording", systemImage: "ear.fill").font(.caption)
                    Label("Noise cancellation during calls", systemImage: "mic.slash.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { checkMicrophones() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Re-check") }
                }
            }
        }
        .navigationTitle("Microphone Array")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkMicrophones() }
    }

    private func checkMicrophones() {
        var info: [(String, String)] = []

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [])
            try session.setActive(true)
        } catch {}

        let inputs = session.availableInputs ?? []
        micCount = 0
        for input in inputs {
            if input.portType == .builtInMic {
                let dataSources = input.dataSources ?? []
                micCount = max(micCount, dataSources.count)
                info.append(("Built-in Mic", input.portName))
                info.append(("Data Sources", "\(dataSources.count)"))
                for (i, source) in dataSources.enumerated() {
                    info.append(("Mic \(i + 1)", "\(source.dataSourceName) (\(source.orientation?.rawValue ?? "Unknown"))"))
                }
            }
        }

        info.append(("Input Channels", "\(session.inputNumberOfChannels)"))
        info.append(("Sample Rate", String(format: "%.0f Hz", session.sampleRate)))
        info.append(("IO Buffer", String(format: "%.1f ms", session.ioBufferDuration * 1000)))

        let currentRoute = session.currentRoute
        let inputPorts = currentRoute.inputs.map { $0.portName }.joined(separator: ", ")
        info.append(("Current Input", inputPorts.isEmpty ? "None" : inputPorts))

        details = info
    }
}
