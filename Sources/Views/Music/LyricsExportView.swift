import SwiftUI

// MARK: - LyricsExportView

struct LyricsExportView: View {
    @StateObject private var engine = LyricsSyncEngine.shared
    @StateObject private var player = MusicPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showShareSheet = false
    @State private var exportURL: URL?

    private var lrcText: String {
        LyricsService().exportLRC(engine.lines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if engine.lines.isEmpty {
                    emptyView
                } else {
                    previewView
                }
            }
            .navigationTitle("Export Lyrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                if !engine.lines.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            prepareExport()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Preview

    private var previewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.currentSong?.title ?? "Unknown")
                            .font(.headline)
                        Text(player.currentSong?.artist ?? "Unknown Artist")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(engine.lines.count) lines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))

                Divider()

                Text(lrcText)
                    .font(.system(.body, design: .monospaced))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No lyrics to export")
                .font(.title3.bold())
            Text("Load or create lyrics first.")
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Export

    private func prepareExport() {
        guard let song = player.currentSong else { return }
        let service = LyricsService()
        service.save(engine.lines, for: song)
        exportURL = service.lrcFileURL(for: song)
        showShareSheet = true
    }
}

// MARK: - UIKit Share Sheet wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
