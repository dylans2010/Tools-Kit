import SwiftUI

struct HistoryInspectorView: View {
    @ObservedObject var historyManager: EditingHistoryManager
    let onJump: (EditingProject) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Edit History")
                .font(.headline)
                .padding()

            List {
                ForEach(Array(historyManager.history.enumerated()), id: \.offset) { index, state in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(state.description)
                                .font(.subheadline)
                                .bold(index == historyManager.currentIndex)
                            Text(state.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if index == historyManager.currentIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let project = historyManager.jumpTo(index: index) {
                            onJump(project)
                        }
                    }
                }
            }

            HStack {
                Button("Undo") {
                    if let project = historyManager.undo() { onJump(project) }
                }
                .disabled(historyManager.currentIndex <= 0)

                Spacer()

                Button("Redo") {
                    if let project = historyManager.redo() { onJump(project) }
                }
                .disabled(historyManager.currentIndex >= historyManager.history.count - 1)
            }
            .padding()
        }
    }
}
