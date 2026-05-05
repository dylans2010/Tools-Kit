import SwiftUI

struct ConnectorExecutionView: View {
    let connector: ConnectorDefinition
    @State private var executionLogs: [String] = []

    var body: some View {
        VStack {
            List {
                Section("Active Pipelines") {
                    ForEach(connector.flows) { flow in
                        HStack {
                            Text(flow.name)
                            Spacer()
                            Button("Trigger") {
                                triggerFlow(flow)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Section("Execution Output") {
                    if executionLogs.isEmpty {
                        Text("No active executions").secondary()
                    } else {
                        ForEach(executionLogs, id: \.self) { log in
                            Text(log).font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            }
        }
        .navigationTitle("Pipeline Execution")
    }

    private func triggerFlow(_ flow: ConnectorFlow) {
        executionLogs.append("[\(Date().formatted())] Triggering flow: \(flow.name)")
        ConnectorRuntime.shared.executeConnector(connector)
        executionLogs.append("[\(Date().formatted())] Flow execution dispatched to engine.")
    }
}
