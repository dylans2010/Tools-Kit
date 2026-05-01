import SwiftUI
import UniformTypeIdentifiers

struct SecurityPackageView: View {
    @State private var password = ""
    @State private var showingExportShare = false
    @State private var exportURL: URL?
    @State private var showingImportPicker = false
    @State private var statusMessage: String?
    @State private var isError = false
    @State private var showingImportBridge = false

    var body: some View {
        NavigationStack {
            List {
                Section("Backup") {
                    Text("Export your entire vault into a single encrypted .toolkitsec file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("Master Password", text: $password)

                    Button {
                        exportVault()
                    } label: {
                        Label("Export Vault", systemImage: "square.and.arrow.up")
                    }
                    .disabled(password.isEmpty)
                }

                Section("Restore") {
                    Text("Import a previously exported .toolkitsec file. This will add items to your current vault.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Import Vault", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        showingImportBridge = true
                    } label: {
                        Label("Import via Document Picker", systemImage: "doc.badge.plus")
                    }
                }

                if let status = statusMessage {
                    Section {
                        Text(status)
                            .foregroundColor(isError ? .red : .green)
                    }
                }
            }
            .navigationTitle("Security Package")
            .sheet(isPresented: $showingExportShare) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [UTType(filenameExtension: "toolkitsec") ?? .data]) { result in
                handleImport(result: result)
            }
            .sheet(isPresented: $showingImportBridge) {
                FileImporterRepresentableView(allowedContentTypes: [UTType(filenameExtension: "toolkitsec") ?? .data], allowsMultipleSelection: false) { urls in
                    handleImport(urls: urls)
                }
            }
        }
    }

    private func exportVault() {
        Task {
            do {
                let url = try await SecurityPackageService.shared.exportPackage(password: password)
                self.exportURL = url
                self.showingExportShare = true
                self.statusMessage = "Backup generated successfully."
                self.isError = false
            } catch {
                self.statusMessage = "Export failed: \(error.localizedDescription)"
                self.isError = true
            }
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            handleImport(urls: urls)
        case .failure(let error):
            self.statusMessage = error.localizedDescription
            self.isError = true
        }
    }

    private func handleImport(urls: [URL]) {
        guard let url = urls.first else { return }
        Task {
            do {
                try await SecurityPackageService.shared.importPackage(at: url, password: password)
                self.statusMessage = "Vault imported successfully."
                self.isError = false
            } catch {
                self.statusMessage = "Import failed: \(error.localizedDescription)"
                self.isError = true
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
