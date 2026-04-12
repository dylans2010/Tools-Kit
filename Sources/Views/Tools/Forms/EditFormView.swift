import SwiftUI
import UniformTypeIdentifiers

struct EditFormView: View {
    @ObservedObject var backend: FormsBackend
    @State var form: FormDocument
    @State private var showingFillOut = false
    @State private var showingAnswerImporter = false
    @State private var exportedURL: URL?

    var body: some View {
        Form {
            Section("Form Details") {
                TextField("Name", text: $form.name)
                TextField("Description", text: $form.description)
                TextField("Accent Hex", text: $form.accentHexColor)
                TextField("Background Hex", text: $form.backgroundHexColor)
            }

            Section("Questions") {
                ForEach($form.questions) { $question in
                    VStack(alignment: .leading) {
                        TextField("Question", text: $question.title)
                        Toggle("Required", isOn: $question.required)
                    }
                }
            }

            Section("Manifest") {
                ManifestDataForm(manifest: form.manifest)
            }

            Section("Actions") {
                Button("Save Changes") { backend.update(form) }
                Button("Fill Out Form") { showingFillOut = true }
                Button("Export .form") { exportForm() }
                if let exportedURL {
                    ShareLink(item: exportedURL) {
                        Label("Share Exported .form", systemImage: "square.and.arrow.up")
                    }
                }
                Button("Import Filled Answers") { showingAnswerImporter = true }
            }

            if let reviewed = backend.reviewedAnswers {
                Section("Reviewed Answers") {
                    Text("Responder: \(reviewed.responderName)")
                    ForEach(form.questions) { question in
                        VStack(alignment: .leading) {
                            Text(question.title).font(.subheadline.bold())
                            Text(reviewed.answers[question.id] ?? "No answer").foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Form")
        .sheet(isPresented: $showingFillOut) {
            NavigationStack { FillOutFormView(form: form, backend: backend) }
        }
        .sheet(isPresented: $showingAnswerImporter) {
            FileImporterRepresentableView(allowedContentTypes: [UTType(filenameExtension: "form") ?? .data]) { urls in
                guard let url = urls.first else { return }
                if let answers = try? FilledOutFormManager.importAnswers(from: url) {
                    backend.reviewedAnswers = answers
                }
            }
        }
    }

    private func exportForm() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(form.name).form")
        try? FormFileManager.exportForm(form, to: url)
        exportedURL = url
    }
}
