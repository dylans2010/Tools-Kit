import SwiftUI
import UniformTypeIdentifiers

struct ImportFormView: View {
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Import a .form file to continue editing or filling it out.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Pick .form File") {
                showPicker = true
            }
            .buttonStyle(.borderedProminent)

            if let form = backend.importedForm {
                ManifestDataForm(manifest: form.manifest)
                    .padding()
                NavigationLink("Open Imported Form") {
                    EditFormView(backend: backend, form: form)
                }
            }
        }
        .padding()
        .sheet(isPresented: $showPicker) {
            FileImporterRepresentableView(allowedContentTypes: [UTType(filenameExtension: "form") ?? .data]) { urls in
                guard let url = urls.first else { return }
                if let imported = try? FormFileManager.importForm(from: url) {
                    backend.importedForm = imported
                    backend.add(imported, isOwned: false)
                }
                dismiss()
            }
        }
    }
}
