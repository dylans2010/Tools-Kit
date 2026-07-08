import SwiftUI
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

struct SecureFileSenderTool: Tool {
    let name = "Secure File Sender"
    let icon = "arrow.up.doc.fill"
    let category = ToolCategory.privacy
    let complexity = ToolComplexity.advanced
    let description = "Upload files and receive expiring secure download links"
    let requiresAPI = false
    var view: AnyView { AnyView(SecureFileSenderView()) }
}

struct SecureFileSenderView: View {
    @StateObject private var backend = SecureFileSenderBackend()
    @State private var showFilePicker = false

    var body: some View {
        ToolDetailView(tool: SecureFileSenderTool()) {
            VStack(spacing: 16) {
                filePickerSection
                if let _ = backend.selectedFileURL {
                    uploadConfigSection
                    uploadButton
                }
                if backend.isUploading {
                    uploadProgressSection
                }
                if let result = backend.uploadResult {
                    resultSection(result)
                }
                if !backend.errorMessage.isEmpty {
                    errorCard
                }
                if !backend.history.isEmpty {
                    historySection
                }
            }
        }
        .navigationTitle("Secure File Sender")
        .sheet(isPresented: $showFilePicker) {
            SecureFilePickerView { url in
                backend.selectFile(url: url)
                showFilePicker = false
            }
        }
    }

    private var filePickerSection: some View {
        ToolInputSection("File") {
            VStack(spacing: 0) {
                Button {
                    showFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "doc.badge.plus").foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(backend.selectedFileName.isEmpty ? "Select file to upload" : backend.selectedFileName)
                                .font(.subheadline)
                            if backend.selectedFileSize > 0 {
                                Text(formattedSize(backend.selectedFileSize))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                    }
                    .padding()
                }
                .foregroundColor(backend.selectedFileName.isEmpty ? .secondary : .primary)
            }
        }
    }

    private var uploadConfigSection: some View {
        ToolInputSection("Expiry") {
            Picker("Expires after", selection: $backend.expiryOption) {
                ForEach(backend.expiryOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding()
        }
    }

    private var uploadButton: some View {
        Button {
            Task { await backend.upload() }
        } label: {
            Label("Upload Securely", systemImage: "arrow.up.circle.fill")
                .frame(maxWidth: .infinity).padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .disabled(backend.isUploading || backend.selectedFileURL == nil)
    }

    private var uploadProgressSection: some View {
        VStack(spacing: 8) {
            ProgressView(value: backend.uploadProgress)
                .progressViewStyle(.linear)
            Text(String(format: "Uploading… %.0f%%", backend.uploadProgress * 100))
                .font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func resultSection(_ result: UploadResult) -> some View {
        ToolInputSection("Upload Complete") {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text(result.filename).font(.subheadline.weight(.medium))
                    Spacer()
                    Text("Expires: \(result.expiry)").font(.caption).foregroundColor(.secondary)
                }
                .padding()
                Divider()
                HStack {
                    Text(result.link)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                        .foregroundColor(.blue)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = result.link
                    } label: {
                        Image(systemName: "doc.on.doc").foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
    }

    private var errorCard: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
            Text(backend.errorMessage).font(.subheadline)
        }
        .padding().frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1)).cornerRadius(12)
    }

    private var historySection: some View {
        ToolInputSection("Upload History") {
            ForEach(backend.history) { result in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.filename).font(.subheadline.weight(.medium)).lineLimit(1)
                        Text(result.link).font(.caption).foregroundColor(.blue).lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(result.expiry).font(.caption2).foregroundColor(.secondary)
                        Text(formattedSize(result.size)).font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding()
                if result.id != backend.history.last?.id { Divider().padding(.leading) }
            }
        }
    }

    private func formattedSize(_ bytes: Int) -> String {
        if bytes >= 1_048_576 { return String(format: "%.1f MB", Double(bytes) / 1_048_576) }
        if bytes >= 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return "\(bytes) B"
    }
}

struct SecureFilePickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .pdf, .image, .text], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { onPick(url) }
        }
    }
}
