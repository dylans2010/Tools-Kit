import SwiftUI
import UniformTypeIdentifiers

struct SecurityPackageView: View {
    @StateObject private var packageService = SecurityPackageService.shared
    @State private var exportURL: URL?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showShareSheet = false
    @State private var importPassword = ""
    @State private var showImportDialog = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Export Security Package")
                        .font(.headline)
                    Text("Creates an encrypted backup of your entire vault. Store this file safely in a separate location.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)

                Button(action: export) {
                    if isExporting {
                        ProgressView()
                    } else {
                        Label("Generate .toolkitsec", systemImage: "arrow.up.doc")
                    }
                }
                .disabled(isExporting)
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Import Security Package")
                        .font(.headline)
                    Text("Restore vault contents from a previously exported .toolkitsec file. This will replace current items.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)

                Button(action: { isImporting = true }) {
                    Label("Restore from Backup", systemImage: "arrow.down.doc")
                }
            }
        }
        .navigationTitle("Backup & Recovery")
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.data]) { result in
            switch result {
            case .success(let url):
                exportURL = url
                showImportDialog = true
            case .failure:
                break
            }
        }
        .alert("Import Package", isPresented: $showImportDialog) {
            SecureField("Master Password", text: $importPassword)
            Button("Import", action: performImport)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter the master password that was used when this package was created.")
        }
    }

    private func export() {
        isExporting = true
        Task {
            do {
                let url = try await packageService.exportPackage()
                await MainActor.run {
                    self.exportURL = url
                    self.showShareSheet = true
                    self.isExporting = false
                }
            } catch {
                await MainActor.run { self.isExporting = false }
            }
        }
    }

    private func performImport() {
        guard let url = exportURL else { return }
        Task {
            do {
                try await packageService.importPackage(from: url, password: importPassword)
                // Success
            } catch {
                // Handle error
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
