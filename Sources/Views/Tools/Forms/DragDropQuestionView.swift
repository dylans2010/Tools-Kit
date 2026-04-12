import SwiftUI

/// Interactive reorderable drag-and-drop question component for filling out a form.
struct DragDropQuestionView: View {
    let question: FormQuestion
    @Binding var answer: String

    @State private var orderedItems: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if orderedItems.isEmpty {
                Text("No items to rank.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Hold and drag to reorder:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                List {
                    ForEach(Array(orderedItems.enumerated()), id: \.element) { index, item in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text(item)
                                .font(.body)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onMove { source, destination in
                        orderedItems.move(fromOffsets: source, toOffset: destination)
                        syncAnswer()
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: CGFloat(orderedItems.count) * 46)
                .environment(\.editMode, .constant(.active))
            }
        }
        .onAppear(perform: initItems)
    }

    private func initItems() {
        let saved = answer
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let base = question.options.isEmpty ? [] : question.options
        if !saved.isEmpty {
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
