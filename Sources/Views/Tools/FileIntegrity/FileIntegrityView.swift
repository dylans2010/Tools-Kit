import SwiftUI
import UniformTypeIdentifiers

struct FileIntegrityTool: Tool {
    let name = "File Integrity"
    let icon = "checkmark.shield.fill"
    let category = ToolCategory.network
    let complexity = ToolComplexity.advanced
    let description = "Generate and verify cryptographic hashes for files to detect tampering"
    let requiresAPI = false
    var view: AnyView { AnyView(FileIntegrityView()) }
}

struct FileIntegrityView: View {
    @StateObject private var backend = FileIntegrityBackend()
    @State private var showFilePicker = false
    @State private var pickedURL: URL?

    var body: some View {
        ToolDetailView(tool: FileIntegrityTool()) {
            VStack(spacing: 16) {
                fileSection
                if backend.isProcessing {
                    ProgressView("Processing…").padding()
                } else if !backend.currentSHA256.isEmpty {
                    hashSection
                }
                if !backend.statusMessage.isEmpty {
                    Text(backend.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                recordsSection
            }
        }
        .navigationTitle("File Integrity")
        .sheet(isPresented: $showFilePicker) {
            FileImporterRepresentableView(
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { urls in
                guard let url = urls.first else { return }
                pickedURL = url
                backend.processFile(url: url)
                showFilePicker = false
            }
        }
    }

    private var fileSection: some View {
        ToolInputSection("Select File") {
            Button(action: { showFilePicker = true }) {
                Label("Choose File to Hash", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

    private var hashSection: some View {
        ToolInputSection("Hashes: \(backend.currentFileName)") {
            VStack(spacing: 0) {
                hashRow("SHA-256", value: backend.currentSHA256)
                Divider()
                hashRow("MD5", value: backend.currentMD5)
                Divider()
                hashRow("SHA-1", value: backend.currentSHA1)
                Divider()
                if let url = pickedURL {
                    Button(action: { backend.saveRecord(url: url) }) {
                        Label("Save as Baseline", systemImage: "bookmark.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
        }
    }

    private func hashRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.bold()).foregroundColor(.secondary)
            HStack {
                Text(value)
                    .font(.system(.caption2, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button {
                    UIPasteboard.general.string = value
                } label: {
                    Image(systemName: "doc.on.doc").font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
    }

    private var recordsSection: some View {
        Group {
            if !backend.records.isEmpty {
                ToolInputSection("Saved Records (\(backend.records.count))") {
                    ForEach(backend.records) { record in
                        recordRow(record)
                        Divider()
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { backend.deleteRecord(backend.records[$0]) }
                    }
                }
            }
        }
    }

    private func recordRow(_ record: FileHashRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tamperIcon(record))
                .foregroundColor(tamperColor(record))
            VStack(alignment: .leading, spacing: 2) {
                Text(record.fileName).font(.subheadline.bold())
                Text(record.sha256.prefix(16) + "…").font(.system(.caption2, design: .monospaced)).foregroundColor(.secondary)
                Text(record.recordedAt, style: .date).font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Button("Verify") { backend.verify(record: record) }
                .font(.caption)
                .buttonStyle(.bordered)
        }
        .padding()
    }

    private func tamperIcon(_ record: FileHashRecord) -> String {
        switch record.tampered {
        case .none: return "doc.fill"
        case .some(true): return "exclamationmark.triangle.fill"
        case .some(false): return "checkmark.circle.fill"
        }
    }

    private func tamperColor(_ record: FileHashRecord) -> Color {
        switch record.tampered {
        case .none: return .secondary
        case .some(true): return .red
        case .some(false): return .green
        }
    }
}
