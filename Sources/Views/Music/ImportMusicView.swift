import SwiftUI
import UniformTypeIdentifiers

struct ImportMusicView: View {
    @StateObject private var library = MusicLibraryManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showFilePicker = false
    @State private var showZIPPicker = false
    @State private var showWiFiTransfer = false
    @State private var isImporting = false
    @State private var importResult: String? = nil
    @State private var importedCount = 0

    private let audioTypes: [UTType] = [
        UTType(filenameExtension: "mp3") ?? .audio,
        UTType(filenameExtension: "m4a") ?? .audio,
        UTType(filenameExtension: "wav") ?? .audio,
        UTType(filenameExtension: "aac") ?? .audio,
        UTType(filenameExtension: "flac") ?? .audio,
        .audio
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    importOption(
                        icon: "music.note",
                        iconColor: .blue,
                        title: "Audio Files",
                        subtitle: "Import .mp3, .m4a, .wav files"
                    ) { showFilePicker = true }

                    importOption(
                        icon: "archivebox.fill",
                        iconColor: .orange,
                        title: "ZIP Archive",
                        subtitle: "Bulk import from a .zip file"
                    ) { showZIPPicker = true }

                    importOption(
                        icon: "wifi",
                        iconColor: .green,
                        title: "WiFi Transfer",
                        subtitle: "Transfer from your computer wirelessly"
                    ) { showWiFiTransfer = true }
                } header: {
                    Text("Import Source")
                }

                if let result = importResult {
                    Section {
                        HStack {
                            Image(systemName: importedCount > 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(importedCount > 0 ? .green : .orange)
                            Text(result)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Import Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if isImporting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Importing…")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: audioTypes,
            allowsMultipleSelection: true
        ) { result in
            handleAudioImport(result: result)
        }
        .fileImporter(
            isPresented: $showZIPPicker,
            allowedContentTypes: [UTType(filenameExtension: "zip") ?? .zip],
            allowsMultipleSelection: false
        ) { result in
            handleZIPImport(result: result)
        }
        .sheet(isPresented: $showWiFiTransfer) {
            WiFiTransferView()
        }
    }

    // MARK: - Import Handlers

    private func handleAudioImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            isImporting = true
            Task {
                var count = 0
                for url in urls {
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    defer { url.stopAccessingSecurityScopedResource() }
                    do {
                        try await library.importAudioFile(from: url)
                        count += 1
                    } catch {
                        InternalLogger.shared.log("ImportMusicView: failed to import \(url.lastPathComponent) — \(error.localizedDescription)", level: .error)
                    }
                }
                await MainActor.run {
                    importedCount = count
                    importResult = count > 0
                        ? "Imported \(count) \(count == 1 ? "file" : "files") successfully."
                        : "No files were imported."
                    isImporting = false
                }
            }
        case .failure(let error):
            importResult = "Failed: \(error.localizedDescription)"
            importedCount = 0
        }
    }

    private func handleZIPImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            isImporting = true
            Task {
                guard url.startAccessingSecurityScopedResource() else {
                    await MainActor.run { isImporting = false }
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                let playlistName = url.deletingPathExtension().lastPathComponent
                if let playlist = await library.importFromZIP(at: url, playlistName: playlistName) {
                    let count = playlist.songIDs.count
                    await MainActor.run {
                        importedCount = count
                        importResult = "Imported \(count) \(count == 1 ? "file" : "files") from ZIP."
                        isImporting = false
                    }
                } else {
                    await MainActor.run {
                        importedCount = 0
                        importResult = "No audio files found in ZIP."
                        isImporting = false
                    }
                }
            }
        case .failure(let error):
            importResult = "Failed: \(error.localizedDescription)"
            importedCount = 0
        }
    }

    // MARK: - Import Option Row

    private func importOption(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
