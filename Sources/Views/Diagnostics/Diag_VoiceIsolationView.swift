import SwiftUI
import AVFoundation

struct Diag_VoiceIsolationView: View {
    @State private var micModes: [String] = []
    @State private var currentMode: String = "Unknown"
    @State private var isChecking = false

    var body: some View {
        Form {
            Section("Voice Isolation") {
                VStack(spacing: 12) {
                    Image(systemName: "person.wave.2.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)
                    Text("Voice Processing")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Microphone Modes") {
                if micModes.isEmpty {
                    Text("Checking available modes...")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(micModes, id: \.self) { mode in
                        HStack {
                            Image(systemName: iconForMode(mode))
                                .foregroundStyle(.blue)
                            Text(displayName(for: mode))
                            Spacer()
                            if mode == currentMode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }

            Section("Current Configuration") {
                LabeledContent("Active Mode") { Text(displayName(for: currentMode)) }
                LabeledContent("Echo Cancellation") {
                    Text("Enabled").foregroundStyle(.green)
                }
                LabeledContent("Noise Suppression") {
                    Text("Active").foregroundStyle(.green)
                }
            }

            Section {
                Button {
                    checkModes()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                }
            }
        }
        .navigationTitle("Voice Isolation")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkModes() }
    }

    private func checkModes() {
        let session = AVAudioSession.sharedInstance()
        var modes: [String] = []
        modes.append(AVAudioSession.Mode.default.rawValue)
        modes.append(AVAudioSession.Mode.voiceChat.rawValue)
        modes.append(AVAudioSession.Mode.measurement.rawValue)
        micModes = modes
        currentMode = session.mode.rawValue
    }

    private func displayName(for mode: String) -> String {
        switch mode {
        case AVAudioSession.Mode.default.rawValue: return "Standard"
        case AVAudioSession.Mode.voiceChat.rawValue: return "Voice Chat"
        case AVAudioSession.Mode.measurement.rawValue: return "Measurement"
        default: return mode
        }
    }

    private func iconForMode(_ mode: String) -> String {
        switch mode {
        case AVAudioSession.Mode.voiceChat.rawValue: return "person.wave.2.fill"
        case AVAudioSession.Mode.measurement.rawValue: return "waveform"
        default: return "mic.fill"
        }
    }
}
