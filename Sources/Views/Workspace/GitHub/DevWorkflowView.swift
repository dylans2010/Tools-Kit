import SwiftUI

struct DevWorkflowView: View {
    var body: some View {
        List {
            Section("GitHub Actions") {
                HStack {
                    Text("Build & Test")
                    Spacer()
                    Text("Passing").foregroundColor(.green)
                }
                HStack {
                    Text("Linting")
                    Spacer()
                    Text("Running...").foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Developer Workflow")
    }
}
