import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_MultiMicSwitchingView: View {
    @State private var availableInputs: [AVAudioSessionPortDescription] = []
    @State private var currentInput: String = "None"
    @State private var isRefreshing = false

    var body: some View {
        Form {
            Section("Current Input") {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.blue)
                    Text(currentInput)
                        .font(.headline)
                }
            }

            Section("Available Microphones") {
                if availableInputs.isEmpty {
                    Text("No additional microphones detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(availableInputs, id: \.uid) { input in
                        Button {
                            selectInput(input)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(input.portName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text(input.portType.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if input.portName == currentInput {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }

            Section("Audio Route") {
                let route = AVAudioSession.sharedInstance().currentRoute
                ForEach(route.inputs, id: \.uid) { port in
                    LabeledContent("Input") {
                        Text(port.portName)
                    }
                }
                ForEach(route.outputs, id: \.uid) { port in
                    LabeledContent("Output") {
                        Text(port.portName)
                    }
                }
            }

            Section {
                Button {
                    refreshInputs()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                }
            }
        }
        .navigationTitle("Multi-Mic Switching")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { refreshInputs() }
    }

    private func refreshInputs() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {}
        availableInputs = session.availableInputs ?? []
        currentInput = session.currentRoute.inputs.first?.portName ?? "None"
    }

    private func selectInput(_ input: AVAudioSessionPortDescription) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setPreferredInput(input)
            currentInput = input.portName
        } catch {}
    }
}
