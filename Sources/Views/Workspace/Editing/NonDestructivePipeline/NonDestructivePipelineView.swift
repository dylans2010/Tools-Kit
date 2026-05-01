import SwiftUI

struct NonDestructivePipelineView: View {
    let projectID: UUID
    @State private var label = ""

    var body: some View {
        Form {
            TextField("Snapshot Label", text: $label)
            Button("Capture Snapshot") {
                NonDestructivePipelineService.shared.capture(projectID: projectID, label: label)
                label = ""
            }.disabled(label.isEmpty)
        }
        .navigationTitle("Non-Destructive")
    }
}
