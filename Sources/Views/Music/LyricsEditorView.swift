import SwiftUI

// MARK: - LyricsEditorView

struct LyricsEditorView: View {
    @StateObject private var engine = LyricsSyncEngine.shared
    @StateObject private var player = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    // Editor state
    @State private var mode: EditorMode = .text
    @State private var rawText: String = ""
    @State private var editableLines: [LyricLine] = []
    @State private var syncLineText: String = ""
    @State private var isDirty: Bool = false
    @State private var showDiscardAlert: Bool = false

    private enum EditorMode: String, CaseIterable {
        case text = "Text"
        case sync = "Sync"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Song title banner
                if let song = player.currentSong {
                    songBanner(song: song)
                }

                // Mode picker
                Picker("Mode", selection: $mode) {
                    ForEach(EditorMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()

                // Content area
                if mode == .text {
                    textModeContent
                } else {
                    syncModeContent
                }
            }
            .navigationTitle("Lyrics Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if isDirty { showDiscardAlert = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadExistingLyrics() }
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Your unsaved changes will be lost.")
            }
        }
    }

    // MARK: - Song Banner

    private func songBanner(song: Song) -> some View {
        HStack(spacing: 12) {
            if let data = song.artworkData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "music.note").foregroundColor(.secondary))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Text Mode

    private var textModeContent: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Paste or type lyrics — one line per row")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $rawText)
                    .font(.body)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: rawText) { _ in isDirty = true }
            }
            .padding(16)

            Divider()

            Button {
                autoSyncLines()
            } label: {
                Label("Auto-Assign Timestamps", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Sync Mode

    private var syncModeContent: some View {
        VStack(spacing: 0) {
            // Playback time display
            HStack {
                Image(systemName: player.isPlaying ? "waveform" : "pause")
                    .foregroundColor(player.isPlaying ? .accentColor : .secondary)
                    .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                Text(formattedTime(player.currentTime))
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                Spacer()
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))

            Divider()

            // Timed lines list
            List {
                Section {
                    ForEach(editableLines) { line in
                        HStack {
                            Text(formattedTimestamp(line.timestamp))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 72, alignment: .leading)
                            Text(line.text)
                                .font(.subheadline)
                        }
                    }
                    .onDelete { offsets in
                        editableLines.remove(atOffsets: offsets)
                        isDirty = true
                    }
                    .onMove { from, to in
                        editableLines.move(fromOffsets: from, toOffset: to)
                        isDirty = true
                    }
                } header: {
                    Text("Timed Lines (\(editableLines.count))")
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(.active))

            Divider()

            // Add line at current time
            HStack(spacing: 10) {
                TextField("Type lyric line…", text: $syncLineText)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit { markLine() }

                Button {
                    markLine()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(syncLineText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .accentColor)
                }
                .disabled(syncLineText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Logic

    private func loadExistingLyrics() {
        editableLines = engine.lines
        rawText = editableLines.map { $0.text }.joined(separator: "\n")
    }

    private func autoSyncLines() {
        let textLines = rawText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !textLines.isEmpty, player.duration > 0 else {
            // Assign zero timestamps if no song loaded
            editableLines = textLines.enumerated().map { i, text in
                LyricLine(timestamp: Double(i), text: text)
            }
            return
        }

        let step = player.duration / Double(textLines.count)
        editableLines = textLines.enumerated().map { i, text in
            LyricLine(timestamp: Double(i) * step, text: text)
        }
        isDirty = true
    }

    private func markLine() {
        let text = syncLineText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let line = LyricLine(timestamp: player.currentTime, text: text)
        editableLines.append(line)
        editableLines.sort { $0.timestamp < $1.timestamp }
        syncLineText = ""
        isDirty = true
    }

    private func saveAndDismiss() {
        let linesToSave: [LyricLine]
        if mode == .text {
            autoSyncLines()
            linesToSave = editableLines
        } else {
            linesToSave = editableLines
        }
        engine.setLines(linesToSave)
        if let song = player.currentSong {
            LyricsService().save(linesToSave, for: song)
        }
        isDirty = false
        dismiss()
    }

    // MARK: - Helpers

    private func formattedTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formattedTimestamp(_ ts: TimeInterval) -> String {
        let m = Int(ts) / 60
        let s = ts.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%05.2f", m, s)
    }
}
