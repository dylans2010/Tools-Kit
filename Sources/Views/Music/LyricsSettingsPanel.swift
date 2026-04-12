import SwiftUI

struct LyricsSettingsPanel: View {
    let song: Song
    @StateObject private var engine = LyricsSyncEngine.shared

    @State private var offsetValue: Double = 0
    @State private var showLyrics: Bool = true
    @Binding var isVisible: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Visibility") {
                    Toggle("Show Lyrics", isOn: $showLyrics)
                }

                Section("Sync Offset") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Offset")
                            Spacer()
                            Text(String(format: "%.1f s", offsetValue))
                                .monospacedDigit()
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $offsetValue, in: -5...5, step: 0.1)
                            .tint(.accentColor)
                        Text("Positive values delay lyrics; negative values advance them.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Source") {
                    ForEach(LyricsSourceType.allCases, id: \.self) { source in
                        Button {
                            switchSource(to: source)
                        } label: {
                            HStack {
                                Text(source.rawValue.capitalized)
                                    .foregroundColor(.primary)
                                Spacer()
                                if currentSourceType == source {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Lyrics Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        applyOffset()
                        isVisible = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            offsetValue = engine.offsetSeconds
        }
    }

    // MARK: - Private

    private var currentSourceType: LyricsSourceType {
        // Derive from engine state – default to synced when lines exist
        engine.lines.isEmpty ? .manual : .synced
    }

    private func applyOffset() {
        engine.saveOffset(offsetValue, for: song)
    }

    private func switchSource(to source: LyricsSourceType) {
        switch source {
        case .lrclib:
            Task {
                await engine.loadLyrics(for: song)
            }
        case .manual, .synced, .imported:
            // Source selection is informational; lyrics already loaded
            break
        }
    }
}
