import SwiftUI

struct SDKLogicEditorView: View {
    @State private var steps: [SDKExecutionStep] = []

    var body: some View {
        List {
            ForEach(steps) { step in
                HStack {
                    Image(systemName: "bolt.fill").foregroundStyle(.orange)
                    Text(step.actionID)
                    Spacer()
                }
            }
            .onDelete { steps.remove(atOffsets: $0) }

            Button(action: addStep) {
                Label("Add Execution Step", systemImage: "plus.circle")
            }
        }
        .navigationTitle("Logic Editor")
    }

    private func addStep() {
        steps.append(SDKExecutionStep(id: UUID(), actionID: "new_action", inputMapping: [:]))
    }
}
