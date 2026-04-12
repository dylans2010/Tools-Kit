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
                        questionOptionsEditor(for: $question)
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
        .toolbar { Button("Close") { dismiss() } }
    }

    private func addQuestion() {
        if let manager = managers.first(where: { $0.type == selectedType }) {
            questions.append(manager.defaultQuestion())
        }
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
                        set: { value in
                            var options = question.wrappedValue.options
                            if options.isEmpty { options = ["", ""] }
                            options[0] = value
                            question.wrappedValue.options = options
                        }
                    )
                )
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                TextField(
                    "Max",
                    text: Binding(
                        get: {
                            question.wrappedValue.options.count > 1
                                ? question.wrappedValue.options[1]
                                : ""
                        },
                        set: { value in
                            var options = question.wrappedValue.options
                            if options.isEmpty { options = ["", ""] }
                            if options.count < 2 { options.append("") }
                            options[1] = value
                            question.wrappedValue.options = options
                        }
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
                        set: { updateSliderOption(question: question, index: 0, value: $0) }
                    )
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                TextField(
                    "Max",
                    text: Binding(
                        get: { question.wrappedValue.options.count > 1 ? question.wrappedValue.options[1] : "" },
                        set: { updateSliderOption(question: question, index: 1, value: $0) }
                    )
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                TextField(
                    "Step",
                    text: Binding(
                        get: { question.wrappedValue.options.count > 2 ? question.wrappedValue.options[2] : "" },
                        set: { updateSliderOption(question: question, index: 2, value: $0) }
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

    private func updateSliderOption(question: Binding<FormQuestion>, index: Int, value: String) {
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
