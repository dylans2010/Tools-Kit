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
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Create Encrypted Package", systemImage: "archivebox.fill")
                    SecureField("Master Password", text: $password)
                    Button { exportVault() } label: { Label("Export Vault", systemImage: "square.and.arrow.up") }
                        .disabled(password.isEmpty || isWorking)
                } header: {
                    Text("Backup")
                }
                Section {
                    Button { showingImportPicker = true } label: { Label("Import Vault", systemImage: "square.and.arrow.down") }
                    Button { showingImportBridge = true } label: { Label("Import File", systemImage: "doc.badge.plus") }
                } header: {
                    Text("Restore")
                }
                if let statusMessage { Label(statusMessage, systemImage: isError ? "xmark.circle.fill" : "checkmark.circle.fill").foregroundStyle(isError ? Color.red : Color.green) }
            }
            .navigationTitle("Security Package")
            .overlay { if isWorking { ProgressView("Processing…") } }
            .sheet(isPresented: $showingExportShare) { if let exportURL { ShareSheet(activityItems: [exportURL]) } }
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [UTType(filenameExtension: "toolkitsec") ?? .data]) { if case .success(let url) = $0 { handleImport(urls: [url]) } }
            .sheet(isPresented: $showingImportBridge) { FileImporterRepresentableView(allowedContentTypes: [UTType(filenameExtension: "toolkitsec") ?? .data], allowsMultipleSelection: false) { handleImport(urls: $0) } }
        }
    }
    private func exportVault() { Task { isWorking = true; defer { isWorking = false }; do { let url = try await SecurityPackageService.shared.exportPackage(password: password); exportURL = url; showingExportShare = true; statusMessage = "Backup Generated Successfully."; isError = false } catch { statusMessage = "Export failed: \(error.localizedDescription)"; isError = true } } }
    private func handleImport(urls: [URL]) { guard let url = urls.first else { return }; Task { isWorking = true; defer { isWorking = false }; do { try await SecurityPackageService.shared.importPackage(at: url, password: password); statusMessage = "Vault Imported Successfully."; isError = false } catch { statusMessage = "Import failed: \(error.localizedDescription)"; isError = true } } }
}
