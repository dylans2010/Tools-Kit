import SwiftUI
import AVFoundation

struct Diag_SpatialAudioView: View {
    @State private var spatialSupported = false
    @State private var currentRoute: String = "Unknown"
    @State private var outputChannels: Int = 0
    @State private var sampleRate: Double = 0

    var body: some View {
        Form {
            Section("Spatial Audio") {
                LabeledContent("Spatial Audio") {
                    Label(spatialSupported ? "Available" : "Not Available",
                          systemImage: spatialSupported ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(spatialSupported ? .green : .red)
                }
            }

            Section("Audio Session") {
                LabeledContent("Current Route") { Text(currentRoute) }
                LabeledContent("Output Channels") { Text("\(outputChannels)").monospacedDigit() }
                LabeledContent("Sample Rate") { Text("\(Int(sampleRate)) Hz").monospacedDigit() }
            }

            Section("Output Ports") {
                let ports = AVAudioSession.sharedInstance().currentRoute.outputs
                if ports.isEmpty {
                    Text("No output ports detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(ports, id: \.uid) { port in
                        LabeledContent(port.portName) {
                            Text(port.portType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Spatial Audio")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkAudio() }
    }

    private func checkAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {}
        currentRoute = session.currentRoute.outputs.first?.portName ?? "None"
        outputChannels = session.outputNumberOfChannels
        sampleRate = session.sampleRate
        spatialSupported = session.currentRoute.outputs.contains { port in
            port.portType == .bluetoothA2DP || port.portType == .builtInSpeaker
        }
    }
}
