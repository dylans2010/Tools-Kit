import SwiftUI

struct WorkflowBuilderView: View {
    @State private var name = ""
    @State private var nlInput = ""
    @State private var steps: [WorkflowStep] = []

    var body: some View {
        Form {
            Section("Workflow Details") {
                TextField("Name", text: $name)
            }

            Section("Natural Language Builder") {
                TextField("E.g., When I create a task, make a note", text: $nlInput)
                Button("Generate Workflow") {
                    if let wf = WorkflowBuilderService.shared.buildFromNaturalLanguage(nlInput) {
                        self.name = wf.name
                        self.steps = wf.steps
                    }
                }
            }

            Section("Steps") {
                ForEach(steps) { step in
                    Text(step.actionType)
                }
                NavigationLink(destination: TriggerPickerView()) {
                    Text("Add Trigger")
                }
                NavigationLink(destination: ActionPickerView()) {
                    Text("Add Action")
                }
            }

            Button("Save Workflow") {
                let wf = Workflow(id: UUID(), name: name, steps: steps)
                AutomationEngine.shared.workflows.append(wf)
            }
            .disabled(name.isEmpty || steps.isEmpty)
        }
        .navigationTitle("Workflow Builder")
    }
}
