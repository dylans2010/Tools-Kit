import SwiftUI

/// Visual editor for building and editing multi-step automation pipelines.
struct AutomationBuilderView: View {
    @StateObject private var viewModel = AutomationBuilderViewModel()

    var body: some View {
        Form {
            Section("Workflow Details") {
                TextField("Workflow Name", text: $viewModel.workflowName)
            }

            Section("Pipeline Steps") {
                ForEach(viewModel.steps) { step in
                    VStack(alignment: .leading) {
                        Text(step.title)
                            .font(.subheadline.bold())
                        Text(step.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: viewModel.deleteStep)

                Button(action: viewModel.addStep) {
                    Label("Add Execution Step", systemName: "plus.circle")
                }
            }

            Section {
                Button(action: viewModel.compileWorkflow) {
                    HStack {
                        Spacer()
                        if viewModel.isCompiling {
                            ProgressView()
                        } else {
                            Text("Compile & Activate")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.workflowName.isEmpty || viewModel.steps.isEmpty)
            }
        }
        .navigationTitle("Automation Builder")
    }
}
