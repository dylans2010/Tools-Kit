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
                        questionOptionsEditor(for: $question)
                    }
                }
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

    @ViewBuilder
    private func questionOptionsEditor(for question: Binding<FormQuestion>) -> some View {
        switch question.wrappedValue.type {
        case .multipleChoice, .dropdown, .dragDrop:
            TextField(
                "Options (comma separated)",
                text: Binding(
                    get: { question.wrappedValue.options.joined(separator: ", ") },
                    set: { question.wrappedValue.options = splitOptions($0) }
                )
            )
            .textFieldStyle(.roundedBorder)
        case .ratingScale:
            HStack {
                TextField(
                    "Min",
                    text: Binding(
                        get: { question.wrappedValue.options.first ?? "" },
                        set: { updateOption(question: question, index: 0, value: $0) }
                    )
                )
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                TextField(
                    "Max",
                    text: Binding(
                        get: { question.wrappedValue.options.count > 1 ? question.wrappedValue.options[1] : "" },
                        set: { updateOption(question: question, index: 1, value: $0) }
                    )
                )
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            }
            .font(.caption)
        case .slider:
            HStack {
                TextField(
                    "Min",
                    text: Binding(
                        get: { question.wrappedValue.options.first ?? "" },
                        set: { updateOption(question: question, index: 0, value: $0) }
                    )
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                TextField(
                    "Max",
                    text: Binding(
                        get: { question.wrappedValue.options.count > 1 ? question.wrappedValue.options[1] : "" },
                        set: { updateOption(question: question, index: 1, value: $0) }
                    )
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                TextField(
                    "Step",
                    text: Binding(
                        get: { question.wrappedValue.options.count > 2 ? question.wrappedValue.options[2] : "" },
                        set: { updateOption(question: question, index: 2, value: $0) }
                    )
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
            }
            .font(.caption)
        case .imageUpload, .textInput:
            EmptyView()
        }
    }

    private func updateOption(question: Binding<FormQuestion>, index: Int, value: String) {
        var options = question.wrappedValue.options
        while options.count <= index {
            options.append("")
        }
        options[index] = value
        question.wrappedValue.options = options
    }

    private func splitOptions(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
