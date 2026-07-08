import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LyricsExportView: View {
    let song: Song
    let lines: [LyricLine]
    @Environment(\.dismiss) private var dismiss

    private let exporter = LRCExporterService()
    @State private var lrcPreview: String = ""
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header info
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.accentColor)
                    Text("\(lines.count) Lines · \(song.title)")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))

                Divider()

                // LRC text preview
                ScrollView {
                    Text(lrcPreview)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }

                Divider()

                // Export button
                Button {
                    shareFile()
                } label: {
                    Label("Share .lrc File", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
            }
            .navigationTitle("Export Lyrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Export Failed", isPresented: .constant(exportError != nil)) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
        }
        .onAppear {
            lrcPreview = exporter.lrcString(from: lines)
        }
    }

    // MARK: - Share

    private func shareFile() {
        do {
            let url = try exporter.exportToFile(lines: lines, songTitle: song.title)
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                // Present from top-most presented controller
                var topVC = root
                while let presented = topVC.presentedViewController { topVC = presented }
                topVC.present(activityVC, animated: true)
            }
        } catch {
            exportError = error.localizedDescription
        }
    }
}
