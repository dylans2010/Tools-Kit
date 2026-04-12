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

            Section("Style") {
                TextField("Accent Hex", text: $accentHex)
                TextField("Background Hex", text: $backgroundHex)
            }

            Section("Questions") {
                Picker("Question Type", selection: $selectedType) {
                    ForEach(FormQuestionType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                Button("Add Question") { addQuestion() }
                ForEach($questions) { $question in
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Question", text: $question.title)
                        Toggle("Required", isOn: $question.required)
                    }
                }
            }

            Button("Create Form") {
                let form = FormDocument(
                    name: name.isEmpty ? "Untitled Form" : name,
                    description: description,
                    questions: questions,
                    accentHexColor: accentHex,
                    backgroundHexColor: backgroundHex,
                    manifest: FormManifest(
                        createdBy: creatorName.isEmpty ? "Unknown" : creatorName,
                        createdAt: Date(),
                        appVersion: "1.0",
                        privacyNote: "Review manifest before sharing."
                    )
                )
                backend.add(form)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Create Form")
        .toolbar { Button("Close") { dismiss() } }
    }

    private func addQuestion() {
        if let manager = managers.first(where: { $0.type == selectedType }) {
            questions.append(manager.defaultQuestion())
        }
    }
}
