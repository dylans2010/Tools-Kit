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
                    DisclosureGroup {
                        QuestionEditorView(question: $question)
                    } label: {
                        HStack {
                            Image(systemName: question.type.icon)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(question.title.isEmpty ? "Untitled Question" : question.title)
                                    .font(.body)
                                Text(question.type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete { form.questions.remove(atOffsets: $0) }
                .onMove { form.questions.move(fromOffsets: $0, toOffset: $1) }
            }

            Section("Manifest") {
                TextField("Created By", text: $form.manifest.createdBy)
                TextField("Privacy Note", text: $form.manifest.privacyNote)
                TextField(
                    "Tags (comma separated)",
                    text: Binding(
                        get: { form.manifest.tags.joined(separator: ", ") },
                        set: { form.manifest.tags = splitOptions($0) }
                    )
                )
                ManifestDataForm(manifest: form.manifest)
            }

            Section("Actions") {
                Button("Save Changes") { saveChanges() }
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
        .toolbar { EditButton() }
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

    private func saveChanges() {
        form.manifest.lastEditedAt = Date()
        form.manifest.questionCount = form.questions.count
        form.manifest.requiredQuestionCount = form.questions.filter(\.required).count
        form.manifest.supportsAttachments = form.questions.contains(where: { $0.type == .imageUpload })
        backend.update(form)
    }

    private func splitOptions(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

