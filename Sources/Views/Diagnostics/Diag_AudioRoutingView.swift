import SwiftUI
import AVFoundation

struct Diag_AudioRoutingView: View {
    @State private var inputPorts: [AVAudioSessionPortDescription] = []
    @State private var outputPorts: [AVAudioSessionPortDescription] = []
    @State private var category: String = ""
    @State private var mode: String = ""
    @State private var isOtherAudioPlaying = false

    var body: some View {
        Form {
            Section("Session Info") {
                LabeledContent("Category") { Text(category).font(.caption) }
                LabeledContent("Mode") { Text(mode).font(.caption) }
                LabeledContent("Other Audio Playing") {
                    Text(isOtherAudioPlaying ? "Yes" : "No")
                        .foregroundStyle(isOtherAudioPlaying ? .orange : .green)
                }
            }

            Section("Output Ports") {
                if outputPorts.isEmpty {
                    Text("No output ports")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(outputPorts, id: \.uid) { port in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(port.portName)
                                .font(.subheadline.weight(.medium))
                            Text(port.portType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Input Ports") {
                if inputPorts.isEmpty {
                    Text("No input ports")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(inputPorts, id: \.uid) { port in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(port.portName)
                                .font(.subheadline.weight(.medium))
                            Text(port.portType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button("Refresh") { loadRouteInfo() }
            }
        }
        .navigationTitle("Audio Routing")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadRouteInfo() }
    }

    private func loadRouteInfo() {
        let session = AVAudioSession.sharedInstance()
        inputPorts = session.currentRoute.inputs
        outputPorts = session.currentRoute.outputs
        category = session.category.rawValue
        mode = session.mode.rawValue
        isOtherAudioPlaying = session.isOtherAudioPlaying
    }
}
