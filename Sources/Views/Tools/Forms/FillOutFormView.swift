import SwiftUI

struct FillOutFormView: View {
    let form: FormDocument
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss

    @State private var answers: [UUID: String] = [:]
    @State private var responderName = ""
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section("Responder") {
                TextField("Your name", text: $responderName)
            }

            Section("Manifest") {
                ManifestDataForm(manifest: form.manifest)
            }

            Section("Questions") {
                ForEach(form.questions) { question in
                    VStack(alignment: .leading) {
                        Text(question.title)
                        questionInput(for: question)
                    }
                }
            }

            Section("Export Answers") {
                Button("Export Filled .form") {
                    exportAnswers()
                }
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share Filled Answers", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("Fill Out Form")
        .toolbar { Button("Done") { dismiss() } }
    }

    @ViewBuilder
    private func questionInput(for question: FormQuestion) -> some View {
        switch question.type {
        case .multipleChoice, .dropdown, .dragDrop:
            Picker("Answer", selection: Binding(
                get: { answers[question.id] ?? "" },
                set: { answers[question.id] = $0 }
            )) {
                ForEach(question.options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        case .ratingScale:
            Picker("Rating", selection: Binding(
                get: { answers[question.id] ?? "3" },
                set: { answers[question.id] = $0 }
            )) {
                ForEach(question.options.isEmpty ? ["1", "2", "3", "4", "5"] : question.options, id: \.self) { value in
                    Text(value).tag(value)
                }
            }
        case .slider:
            Slider(
                value: Binding(
                    get: { Double(answers[question.id] ?? "50") ?? 50 },
                    set: { answers[question.id] = String(Int($0)) }
                ),
                in: 0...100
            )
        case .imageUpload:
            Text("Attach image externally and describe reference here.")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("Image notes", text: Binding(
                get: { answers[question.id] ?? "" },
                set: { answers[question.id] = $0 }
            ))
        case .textInput:
            TextField("Your answer", text: Binding(
                get: { answers[question.id] ?? "" },
                set: { answers[question.id] = $0 }
            ))
        }
    }

    private func exportAnswers() {
        let doc = FilledOutFormDocument(
            formID: form.id,
            formName: form.name,
            answeredAt: Date(),
            answers: answers,
            responderName: responderName.isEmpty ? "Anonymous" : responderName
        )
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(form.name)-answers.form")
        try? FilledOutFormManager.exportAnswers(doc, to: url)
        exportURL = url
    }
}
