import SwiftUI

/// Interactive dropdown (menu picker) question component for filling out a form.
struct DropdownQuestionView: View {
    let question: FormQuestion
    @Binding var answer: String

    var body: some View {
        Menu {
            if answer.isEmpty {
                Button("Select an option…") { }
                    .disabled(true)
            }
            ForEach(question.options, id: \.self) { option in
                Button(option) { answer = option }
            }
            if !answer.isEmpty {
                Divider()
                Button(role: .destructive) {
                    answer = ""
                } label: {
                    Label("Clear selection", systemImage: "xmark.circle")
                }
            }
        } label: {
            HStack {
                Text(answer.isEmpty ? "Select an option…" : answer)
                    .foregroundColor(answer.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
    }
}
