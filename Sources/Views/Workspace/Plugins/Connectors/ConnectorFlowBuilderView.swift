import SwiftUI

struct ConnectorFlowBuilderView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var manager = ConnectorManager.shared

    @State private var steps: [FlowStep]

    init(connector: ConnectorDefinition) {
        self.connector = connector
        _steps = State(initialValue: connector.flow.steps)
    }

    var body: some View {
        List {
            Section("Workflow Pipeline") {
                if steps.isEmpty {
                    Text("No steps defined. Add a trigger to start.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach($steps) { $step in
                        stepRow(step: $step)
                    }
                    .onMove { indices, newOffset in
                        steps.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    .onDelete { indices in
                        steps.remove(atOffsets: indices)
                    }
                }
            }

            Section {
                Menu {
                    Button("Add Trigger") { addStep(.trigger) }
                    Button("Add Condition") { addStep(.condition) }
                    Button("Add Action") { addStep(.action) }
                    Button("Add Delay") { addStep(.delay) }
                } label: {
                    Label("Add Step", systemImage: "plus.circle")
                }
            }

            Section {
                Button("Save Workflow") {
                    connector.flow = ConnectorFlow(steps: steps)
                    manager.updateConnector(connector)
                }
                .frame(maxWidth: .infinity)
                .bold()
                .disabled(steps.isEmpty)
            }
        }
        .navigationTitle("Flow Builder")
        .toolbar {
            EditButton()
        }
    }

    private func stepRow(step: Binding<FlowStep>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                stepIcon(step.wrappedValue.type)
                Text(step.wrappedValue.type.rawValue.capitalized)
                    .font(.headline)
                Spacer()
            }

            switch step.wrappedValue.type {
            case .trigger:
                TextField("Trigger Name (e.g. Daily Sync)", text: Binding(
                    get: { step.wrappedValue.config["name"] ?? "" },
                    set: { step.wrappedValue.config["name"] = $0 }
                ))
            case .condition:
                TextField("JS Condition (e.g. response.status == 200)", text: Binding(
                    get: { step.wrappedValue.config["js_condition"] ?? "" },
                    set: { step.wrappedValue.config["js_condition"] = $0 }
                ))
                .font(.system(.caption, design: .monospaced))
            case .action:
                Picker("Endpoint", selection: Binding(
                    get: { step.wrappedValue.config["endpointID"] ?? "" },
                    set: { step.wrappedValue.config["endpointID"] = $0 }
                )) {
                    Text("Select Endpoint").tag("")
                    ForEach(connector.endpoints) { ep in
                        Text(ep.path).tag(ep.id.uuidString)
                    }
                }
            case .delay:
                HStack {
                    Text("Seconds:")
                    TextField("0", text: Binding(
                        get: { step.wrappedValue.config["seconds"] ?? "0" },
                        set: { step.wrappedValue.config["seconds"] = $0 }
                    ))
                    .keyboardType(.numberPad)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func stepIcon(_ type: FlowStep.StepType) -> some View {
        let name: String
        let color: Color
        switch type {
        case .trigger: name = "bolt.fill"; color = .orange
        case .condition: name = "arrow.branch"; color = .purple
        case .action: name = "play.fill"; color = .blue
        case .delay: name = "clock.fill"; color = .gray
        }
        return Image(systemName: name).foregroundColor(color)
    }

    private func addStep(_ type: FlowStep.StepType) {
        steps.append(FlowStep(type: type, config: [:]))
    }
}
