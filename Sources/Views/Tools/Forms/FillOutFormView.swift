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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: question.type.icon)
                                .foregroundColor(.blue)
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(question.title)
                                    .font(.subheadline.bold())
                                if !question.questionName.isEmpty {
                                    Text("Field: \(question.questionName)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            if question.required {
                                Spacer()
                                Text("Required")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        questionInput(for: question)
                    }
                    .padding(.vertical, 4)
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
        case .dragDrop:
            DragDropQuestionFillerView(
                question: question,
                answer: Binding(
                    get: { answers[question.id] ?? "" },
                    set: { answers[question.id] = $0 }
                )
            )
        case .multipleChoice:
            if question.options.isEmpty {
                TextField("Your answer", text: answerBinding(question.id))
            } else {
                Picker("Answer", selection: answerBinding(question.id)) {
                    Text("Select an option").tag("")
                    ForEach(question.options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
        case .dropdown:
            if question.options.isEmpty {
                TextField("Your answer", text: answerBinding(question.id))
            } else {
                Picker("Answer", selection: answerBinding(question.id)) {
                    Text("Select an option").tag("")
                    ForEach(question.options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        case .ratingScale:
            let ratingOptions = resolvedRatingOptions(for: question)
            Picker("Rating", selection: answerBinding(question.id)) {
                Text("Select a rating").tag("")
                ForEach(ratingOptions, id: \.self) { value in
                    Text(value).tag(value)
                }
            }
            .pickerStyle(.segmented)
        case .slider:
            let sliderConfig = resolvedSliderConfig(for: question)
            VStack(alignment: .leading, spacing: 4) {
                Slider(
                    value: Binding(
                        get: { Double(answers[question.id] ?? String(sliderConfig.defaultValue)) ?? sliderConfig.defaultValue },
                        set: { answers[question.id] = String(Int($0)) }
                    ),
                    in: sliderConfig.min...sliderConfig.max,
                    step: sliderConfig.step
                )
                Text("Value: \(answers[question.id] ?? String(Int(sliderConfig.defaultValue)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .imageUpload:
            VStack(alignment: .leading, spacing: 4) {
                Text("Attach image externally and describe reference here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Image notes", text: answerBinding(question.id))
            }
        case .textInput:
            TextField("Your answer", text: answerBinding(question.id))
        }
    }

    private func answerBinding(_ id: UUID) -> Binding<String> {
        Binding(
            get: { answers[id] ?? "" },
            set: { answers[id] = $0 }
        )
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

    private func resolvedRatingOptions(for question: FormQuestion) -> [String] {
        if question.options.count >= 2,
           let min = Int(question.options[0]),
           let max = Int(question.options[1]),
           min <= max {
            return Array(min...max).map(String.init)
        }
        let normalized = question.options.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return normalized.isEmpty ? ["1", "2", "3", "4", "5"] : normalized
    }

    private func resolvedSliderConfig(for question: FormQuestion) -> (min: Double, max: Double, step: Double, defaultValue: Double) {
        let min = Double(question.options.first ?? "") ?? 0
        let maxCandidate = Double(question.options.count > 1 ? question.options[1] : "") ?? 100
        let maxValue = Swift.max(min, maxCandidate)
        let step = Swift.max(0.1, Double(question.options.count > 2 ? question.options[2] : "") ?? 1)
        return (min, maxValue, step, (min + maxValue) / 2)
    }
}

