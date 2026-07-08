import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct LyricsImportView: View {
    let song: Song
    var onImport: (([LyricLine]) -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var showFilePicker = false
    @State private var previewLines: [LyricLine] = []
    @State private var isPreviewing = false
    @State private var importError: String?

    private let parser = LRCParserService()
    private let service = LyricsService()

    var body: some View {
        NavigationStack {
            Group {
                if isPreviewing {
                    previewView
                } else {
                    promptView
                }
            }
            .navigationTitle("Import Lyrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                if isPreviewing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") { commitImport() }
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showFilePicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [UTType(filenameExtension: "lrc") ?? .plainText]
                ) { urls in
                    showFilePicker = false
                    guard let url = urls.first else { return }
                    loadFile(url: url)
                }
            }
            .alert("Import Failed", isPresented: .constant(importError != nil)) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
        }
        .onAppear { showFilePicker = true }
    }

    // MARK: - Prompt

    private var promptView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text("Select a .lrc File")
                .font(.title2.bold())
            Text("Choose an LRC file from Files to import\nlyrics for \"\(song.title)\".")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showFilePicker = true
            } label: {
                Label("Choose File", systemImage: "folder")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Preview

    private var previewView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("\(previewLines.count) lines parsed")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Choose Different File") {
                    isPreviewing = false
                    showFilePicker = true
                }
                .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))

            Divider()

            List(previewLines) { line in
                HStack(alignment: .top, spacing: 12) {
                    Text(formatTimestamp(line.timestamp))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                    Text(line.text)
                        .font(.body)
                        .lineLimit(2)
                }
                .padding(.vertical, 2)
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Actions

    private func loadFile(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            importError = "Could not read the selected file."
            return
        }
        let parsed = parser.parse(content)
        guard !parsed.isEmpty else {
            importError = "No valid lyric lines found in the file."
            return
        }
        previewLines = parsed
        isPreviewing = true
    }

    private func commitImport() {
        service.save(previewLines, for: song)
        onImport?(previewLines)
        dismiss()
    }

    private func formatTimestamp(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = t.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%05.2f", m, s)
    }
}
