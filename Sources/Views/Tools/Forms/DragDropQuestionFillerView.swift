import SwiftUI

/// Drag-and-drop reordering UI used when filling out a Drag & Drop form question.
struct DragDropQuestionFillerView: View {
    let question: FormQuestion
    @Binding var answer: String

    /// Local ordered list of item names the user can reorder.
    @State private var orderedItems: [String] = []

    init(question: FormQuestion, answer: Binding<String>) {
        self.question = question
        self._answer = answer
        let initial = question.options.isEmpty ? [] : question.options
        self._orderedItems = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if orderedItems.isEmpty {
                Text("No Items To Rank")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Drag items to set your preferred order:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                List {
                    ForEach(orderedItems, id: \.self) { item in
                        HStack(spacing: 10) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                            Text(item)
                                .font(.body)
                        }
                    }
                    .onMove { source, destination in
                        orderedItems.move(fromOffsets: source, toOffset: destination)
                        syncAnswer()
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: CGFloat(orderedItems.count) * 44)
                .environment(\.editMode, .constant(.active))
            }
        }
        .onAppear { initItems() }
    }

    private func initItems() {
        // If the answer was previously saved, restore that order; otherwise use defaults.
        let saved = answer
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let base = question.options.isEmpty ? [] : question.options
        if !saved.isEmpty {
            // Restore saved order, appending any new items at the end.
            let knownSet = Set(base)
            let restored = saved.filter { knownSet.contains($0) }
            let extra = base.filter { !Set(restored).contains($0) }
            orderedItems = restored + extra
        } else {
            orderedItems = base
        }
        syncAnswer()
    }

    private func syncAnswer() {
        answer = orderedItems.joined(separator: ", ")
    }
}
