import SwiftUI

struct AudioControlsView: View {
    @StateObject private var engine = AudioEngineManager.shared

    var body: some View {
        Form {
            playbackSection
            crossfadeSection
            outputSection
            equalizerShortcutSection
        }
        .navigationTitle("Audio Controls")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Playback Section

    private var playbackSection: some View {
        Section {
            // Speed
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Playback Speed", systemImage: "speedometer")
                    Spacer()
                    Text(speedLabel)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.accentColor)
                        .monospacedDigit()
                }
                Slider(value: Binding(
                    get: { Double(engine.playbackRate) },
                    set: {
                        engine.playbackRate = Float($0)
                        engine.applyRate()
                        engine.saveSettings()
                    }
                ), in: 0.5...2.0, step: 0.05)
                HStack {
                    Text("0.5×").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("1×").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                    Text("2×").font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)

            Button {
                engine.playbackRate = 1.0
                engine.applyRate()
                engine.saveSettings()
            } label: {
                Label("Reset to Normal Speed", systemImage: "arrow.counterclockwise")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Playback")
        }
    }

    private var speedLabel: String {
        let r = engine.playbackRate
        if abs(r - 1.0) < 0.01 { return "Normal" }
        return String(format: "%.2f×", r)
    }

    // MARK: - Crossfade Section

    private var crossfadeSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { engine.crossfadeEnabled },
                set: {
                    engine.crossfadeEnabled = $0
                    engine.saveSettings()
                }
            )) {
                Label("Crossfade Tracks", systemImage: "arrow.left.arrow.right")
            }

            if engine.crossfadeEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Duration")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1fs", engine.crossfadeDuration))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.accentColor)
                            .monospacedDigit()
                    }
                    Slider(value: Binding(
                        get: { engine.crossfadeDuration },
                        set: {
                            engine.crossfadeDuration = $0
                            engine.saveSettings()
                        }
                    ), in: 1...12, step: 0.5)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Crossfade")
        } footer: {
            Text("Smoothly fades between tracks so there's no gap or abrupt cut when the next song begins.")
        }
    }

    // MARK: - Output Section

    private var outputSection: some View {
        Section {
            Picker(selection: Binding(
                get: { engine.outputMode },
                set: {
                    engine.outputMode = $0
                    engine.saveSettings()
                }
            )) {
                ForEach(AudioOutputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            } label: {
                Label("Output Mode", systemImage: "speaker.wave.2")
            }
            .pickerStyle(.menu)
        } header: {
            Text("Output")
        } footer: {
            Text("Mono mixes both channels so audio sounds the same on both ears, useful when one earphone is missing.")
        }
    }

    // MARK: - Equalizer Shortcut

    private var equalizerShortcutSection: some View {
        Section {
            NavigationLink {
                EqualizerView()
            } label: {
                HStack {
                    Label("Equalizer", systemImage: "waveform.path.ecg")
                    Spacer()
                    if engine.equalizerEnabled {
                        Text("On")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
        } header: {
            Text("Sound Shaping")
        }
    }
}
