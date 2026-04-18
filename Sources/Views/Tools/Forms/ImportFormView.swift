import SwiftUI
import UniformTypeIdentifiers

struct ImportFormView: View {
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                Text("Import Form")
                    .font(.title3.bold())
                Text("Import a `.form` file to continue editing or filling it out.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button("Pick .form File") { showPicker = true }
                .buttonStyle(.borderedProminent)

            if let form = backend.importedForm {
                ManifestDataForm(manifest: form.manifest)
                    .padding()
                NavigationLink("Open Imported Form") {
                    EditFormView(backend: backend, form: form)
                }
            }

            if let importError {
                Text(importError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .sheet(isPresented: $showPicker) {
            FileImporterRepresentableView(allowedContentTypes: [UTType(filenameExtension: "form") ?? .data]) { urls in
                guard let url = urls.first else { return }
                do {
                    let imported = try FormFileManager.importForm(from: url)
                    backend.importedForm = imported
                    backend.add(imported, isOwned: false)
                    importError = nil
                } catch {
                    importError = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
