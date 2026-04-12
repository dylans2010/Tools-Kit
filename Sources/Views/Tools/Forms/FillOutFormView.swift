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
            if question.options.isEmpty {
                TextField(
                    "Your answer",
                    text: Binding(
                        get: { answers[question.id] ?? "" },
                        set: { answers[question.id] = $0 }
                    )
                )
            } else {
                Picker("Answer", selection: Binding(
                    get: { answers[question.id] ?? "" },
                    set: { answers[question.id] = $0 }
                )) {
                    Text("Select an option").tag("")
                    ForEach(question.options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            }
        case .ratingScale:
            let ratingOptions = resolvedRatingOptions(for: question)
            Picker("Rating", selection: Binding(
                get: { answers[question.id] ?? "" },
                set: { answers[question.id] = $0 }
            )) {
                Text("Select a rating").tag("")
                ForEach(ratingOptions, id: \.self) { value in
                    Text(value).tag(value)
                }
            }
        case .slider:
            let sliderConfig = resolvedSliderConfig(for: question)
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
