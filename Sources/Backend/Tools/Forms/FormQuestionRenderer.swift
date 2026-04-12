import SwiftUI

/// Dynamically maps a FormQuestion to its corresponding interactive SwiftUI view.
/// Bind `answers[question.id]` (a String) and this renderer picks the correct component.
struct FormQuestionRenderer: View {
    let question: FormQuestion
    @Binding var answer: String

    var body: some View {
        Group {
            switch question.type {
            case .textInput:
                TextInputQuestionView(question: question, answer: $answer)
            case .multipleChoice:
                MultipleChoiceQuestionView(question: question, answer: $answer)
            case .dropdown:
                DropdownQuestionView(question: question, answer: $answer)
            case .ratingScale:
                RatingQuestionView(question: question, answer: $answer)
            case .slider:
                SliderQuestionView(question: question, answer: $answer)
            case .imageUpload:
                ImageUploadQuestionView(question: question, answer: $answer)
            case .dragDrop:
                DragDropQuestionView(question: question, answer: $answer)
            }
        }
    }
}

// MARK: - Multiple Choice (stays inline in renderer)

private struct MultipleChoiceQuestionView: View {
    let question: FormQuestion
    @Binding var answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if question.options.isEmpty {
                TextField("Your answer", text: $answer)
                    .textFieldStyle(.roundedBorder)
            } else {
                ForEach(question.options, id: \.self) { option in
                    Button {
                        answer = option
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: answer == option ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(answer == option ? .blue : .secondary)
                            Text(option)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
