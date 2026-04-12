import SwiftUI
import UniformTypeIdentifiers

// MARK: - LyricsImportView

struct LyricsImportView: View {
    @StateObject private var engine = LyricsSyncEngine.shared
    @StateObject private var player = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showFilePicker = false
    @State private var previewLines: [LyricLine] = []
    @State private var errorMessage: String?
    @State private var hasParsed = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    if hasParsed {
                        previewSection
                    } else {
                        placeholderSection
                    }
                }
            }
            .navigationTitle("Import Lyrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if hasParsed {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { saveImported() }
                            .fontWeight(.semibold)
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "lrc") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFilePick(result)
            }
        }
    }

    // MARK: - Placeholder

    private var placeholderSection: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "square.and.arrow.down.on.square")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            VStack(spacing: 8) {
                Text("Import a .lrc File")
                    .font(.title2.bold())
                Text("Select an LRC file to preview its\nlyrics before saving.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button {
                showFilePicker = true
            } label: {
                Label("Choose File", systemImage: "folder")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(previewLines.count) lines parsed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    hasParsed = false
                    previewLines = []
                    errorMessage = nil
                } label: {
                    Label("Choose Different File", systemImage: "folder")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))

            Divider()

            List(previewLines) { line in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(formattedTimestamp(line.timestamp))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 72, alignment: .leading)
                    Text(line.text)
                        .font(.subheadline)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Actions

    private func handleFilePick(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            guard let lrc = try? String(contentsOf: url, encoding: .utf8) else {
                errorMessage = "Failed to read file."
                return
            }
            let service = LyricsService()
            let parsed = service.parseLRC(lrc)
            if parsed.isEmpty {
                errorMessage = "No valid lyric lines found in this file."
            } else {
                previewLines = parsed
                hasParsed = true
                errorMessage = nil
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func saveImported() {
        guard let song = player.currentSong else { dismiss(); return }
        let service = LyricsService()
        service.save(previewLines, for: song)
        engine.setLines(previewLines)
        dismiss()
    }

    // MARK: - Helpers

    private func formattedTimestamp(_ ts: TimeInterval) -> String {
        let m = Int(ts) / 60
        let s = ts.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%05.2f", m, s)
    }
}
