import SwiftUI

struct CreateFormView: View {
    @ObservedObject var backend: FormsBackend
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var questions: [FormQuestion] = []
    @State private var selectedType: FormQuestionType = .textInput
    @State private var accentHex = "007AFF"
    @State private var backgroundHex = "F2F2F7"
    @State private var creatorName = "User"
    @State private var privacyNote = "Review manifest before sharing."
    @State private var tags = ""

    private let managers: [FormOptionManager] = [
        TextInputOptionManager(),
        MultipleChoiceOptionManager(),
        RatingScaleOptionManager(),
        SliderOptionManager(),
        DropdownOptionManager(),
        ImageUploadOptionManager(),
        DragDropOptionManager()
    ]

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Form Name", text: $name)
                TextField("Description", text: $description)
                TextField("Creator Name", text: $creatorName)
            }

            Section("Manifest") {
                TextField("Privacy Note", text: $privacyNote)
                TextField("Tags (comma separated)", text: $tags)
            }

            Section("Style") {
                TextField("Accent Hex", text: $accentHex)
                TextField("Background Hex", text: $backgroundHex)
            }

            Section("Add Question") {
                Picker("Question Type", selection: $selectedType) {
                    ForEach(FormQuestionType.allCases) { type in
                        Label(type.displayName, systemImage: type.icon).tag(type)
                    }
                }
                Button {
                    addQuestion()
                } label: {
                    Label("Add Question", systemImage: "plus.circle.fill")
                }
            }

            if !questions.isEmpty {
                Section("Questions") {
                    ForEach($questions) { $question in
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
                    .onDelete { questions.remove(atOffsets: $0) }
                    .onMove { questions.move(fromOffsets: $0, toOffset: $1) }
                }
            }

            Button("Create Form") {
                let form = FormDocument(
                    name: name.isEmpty ? "Untitled Form" : name,
                    description: description,
                    questions: questions,
                    accentHexColor: accentHex,
                    backgroundHexColor: backgroundHex,
                    manifest: FormManifest.compose(
                        creatorName: creatorName,
                        questions: questions,
                        privacyNote: privacyNote,
                        tags: splitOptions(tags)
                    )
                )
                backend.add(form)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Create Form")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) { EditButton() }
        }
    }

    private func addQuestion() {
        if let manager = managers.first(where: { $0.type == selectedType }) {
            questions.append(manager.defaultQuestion())
        }
    }

    private func splitOptions(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

