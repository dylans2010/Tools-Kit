import SwiftUI
import UniformTypeIdentifiers

// MARK: - LyricsEditorView

struct LyricsEditorView: View {
    let song: Song
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = MusicPlayerManager.shared
    @StateObject private var engine = LyricsSyncEngine.shared

    // Modes
    enum EditorMode: String, CaseIterable {
        case text = "Text"
        case sync = "Sync"
    }

    @State private var mode: EditorMode = .text

    // Text Mode
    @State private var rawText: String = ""

    // Sync Mode
    @State private var syncLines: [LyricLine] = []
    @State private var currentLineInput: String = ""

    // Shared
    private let service = LyricsService()
    private let parser = LRCParserService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(EditorMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()

                if mode == .text {
                    textModeView
                } else {
                    syncModeView
                }
            }
            .navigationTitle(song.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveAndDismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear { loadExistingLyrics() }
    }

    // MARK: - Text Mode

    private var textModeView: some View {
        VStack(spacing: 0) {
            TextEditor(text: $rawText)
                .font(.system(size: 16, design: .default))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            HStack {
                Text("\(rawText.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count) lines")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    autoSyncLines()
                } label: {
                    Label("Auto-Sync Lines", systemImage: "wand.and.stars")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Sync Mode

    private var syncModeView: some View {
        VStack(spacing: 0) {
            // Mini playback info
            playbackBar

            Divider()

            // Synced lines list
            ScrollViewReader { proxy in
                List {
                    ForEach(Array(syncLines.enumerated()), id: \.element.id) { idx, line in
                        syncLineRow(line: line, idx: idx)
                            .id(idx)
                    }
                    .onDelete { offsets in
                        syncLines.remove(atOffsets: offsets)
                    }
                    .onMove { from, to in
                        syncLines.move(fromOffsets: from, toOffset: to)
                    }
                }
                .listStyle(.plain)
                .onChange(of: syncLines.count) { _, _ in
                    if let last = syncLines.indices.last {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            Divider()

            // Input + mark time
            syncInputBar
        }
    }

    private var playbackBar: some View {
        HStack(spacing: 12) {
            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(formatTime(player.currentTime))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private func syncLineRow(line: LyricLine, idx: Int) -> some View {
        HStack(spacing: 12) {
            Text(formatTime(line.timestamp))
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(line.text)
                .font(.body)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    private var syncInputBar: some View {
        HStack(spacing: 10) {
            TextField("Type Lyric Line", text: $currentLineInput)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit { markTime() }

            Button {
                markTime()
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10))
            }
            .disabled(currentLineInput.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    // MARK: - Actions

    private func loadExistingLyrics() {
        let existing = service.loadSaved(for: song) ?? []
        if !existing.isEmpty {
            // Populate text mode with LRC string
            let exporter = LRCExporterService()
            rawText = exporter.lrcString(from: existing)
            syncLines = existing
        }
    }

    private func autoSyncLines() {
        // Try to parse as LRC first; if that yields no results, evenly distribute
        let parsed = parser.parse(rawText)
        if !parsed.isEmpty {
            syncLines = parsed
            rawText = LRCExporterService().lrcString(from: parsed)
        } else {
            let textLines = rawText
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            guard !textLines.isEmpty else { return }
            let dur = song.duration > 0 ? song.duration : Double(textLines.count * 3)
            let step = dur / Double(textLines.count)
            syncLines = textLines.enumerated().map { i, text in
                LyricLine(timestamp: Double(i) * step, text: text)
            }
            rawText = LRCExporterService().lrcString(from: syncLines)
        }
    }

    private func markTime() {
        let text = currentLineInput.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let line = LyricLine(timestamp: player.currentTime, text: text)
        syncLines.append(line)
        currentLineInput = ""
    }

    private func saveAndDismiss() {
        var lines: [LyricLine]
        if mode == .text {
            // Parse text mode (may already be LRC or plain text after auto-sync)
            let parsed = parser.parse(rawText)
            lines = parsed.isEmpty ? syncLines : parsed
        } else {
            lines = syncLines
        }
        guard !lines.isEmpty else { dismiss(); return }
        service.save(lines, for: song)
        engine.setLines(lines)
        dismiss()
    }

    private func formatTime(_ t: TimeInterval) -> String {
        guard t.isFinite, t >= 0 else { return "0:00" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}
