import SwiftUI

/// Interactive text input question component for filling out a form.
struct TextInputQuestionView: View {
    let question: FormQuestion
    @Binding var answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if question.options.first == "multiline" {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(uiColor: .secondarySystemBackground))
                    TextEditor(text: $answer)
                        .frame(minHeight: 80)
                        .padding(8)
                }
                .frame(minHeight: 96)
            } else {
                TextField("Your Answer…", text: $answer)
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(2)
    }
}
