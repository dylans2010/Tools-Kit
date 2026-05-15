import SwiftUI

/// Reusable editor for a single FormQuestion's type-specific options and metadata.
struct QuestionEditorView: View {
    @Binding var question: FormQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Name") {
                TextField("Question Name", text: $question.questionName)
                    .textFieldStyle(.roundedBorder)
            }

            LabeledContent("Question") {
                TextField("What's The Question", text: $question.title)
                    .textFieldStyle(.roundedBorder)
            }

            Toggle("Required", isOn: $question.required)
                .font(.caption)

            // Type-specific option editor
            typeEditor
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var typeEditor: some View {
        switch question.type {
        case .multipleChoice:
            NamedOptionsEditorView(
                label: "Choices",
                placeholder: "Choice Label",
                options: $question.options
            )
        case .dropdown:
            NamedOptionsEditorView(
                label: "Items",
                placeholder: "Dropdown Item",
                options: $question.options
            )
        case .dragDrop:
            NamedOptionsEditorView(
                label: "Items To Rank",
                placeholder: "Item Name",
                options: $question.options
            )
        case .ratingScale:
            RatingScaleEditorView(options: $question.options)
        case .slider:
            SliderEditorView(options: $question.options)
        case .textInput, .imageUpload:
            EmptyView()
        }
    }
}

// MARK: - Named Options Editor

/// Lets users add/remove/reorder individually named option elements.
struct NamedOptionsEditorView: View {
    let label: String
    let placeholder: String
    @Binding var options: [String]
    @State private var newOption = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.secondary)

            ForEach(Array(options.enumerated()), id: \.offset) { index, _ in
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    TextField("\(placeholder) \(index + 1)", text: $options[index])
                        .textFieldStyle(.roundedBorder)
                    Button {
                        options.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                TextField("New \(placeholder.lowercased())…", text: $newOption)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = newOption.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    options.append(trimmed)
                    newOption = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Rating Scale Editor

struct RatingScaleEditorView: View {
    @Binding var options: [String]

    var minBinding: Binding<String> {
        Binding(
            get: { options.first ?? "1" },
            set: { setOption(0, $0) }
        )
    }
    var maxBinding: Binding<String> {
        Binding(
            get: { options.count > 1 ? options[1] : "5" },
            set: { setOption(1, $0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Scale Range")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            HStack {
                TextField("Min", text: minBinding)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Text("to")
                    .foregroundColor(.secondary)
                    .font(.caption)
                TextField("Max", text: maxBinding)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
            .font(.caption)
        }
        .padding(10)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func setOption(_ index: Int, _ value: String) {
        var opts = options
        while opts.count <= index { opts.append("") }
        opts[index] = value
        options = opts
    }
}

// MARK: - Slider Editor

struct SliderEditorView: View {
    @Binding var options: [String]

    var minBinding: Binding<String> { makeBinding(0) }
    var maxBinding: Binding<String> { makeBinding(1) }
    var stepBinding: Binding<String> { makeBinding(2) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Slider Range & Step")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Min").font(.caption2).foregroundColor(.secondary)
                    TextField("Min", text: minBinding).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Max").font(.caption2).foregroundColor(.secondary)
                    TextField("Max", text: maxBinding).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Step").font(.caption2).foregroundColor(.secondary)
                    TextField("Step", text: stepBinding).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                }
            }
            .font(.caption)
        }
        .padding(10)
        .background(Color(uiColor: .tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func makeBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { options.count > index ? options[index] : "" },
            set: { value in
                var opts = options
                while opts.count <= index { opts.append("") }
                opts[index] = value
                options = opts
            }
        )
    }
}
