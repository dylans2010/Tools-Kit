import SwiftUI

struct ConnectorFlowBuilderView: View {
    @Binding var flows: [ConnectorFlow]

    var body: some View {
        List {
            ForEach(flows) { flow in
                NavigationLink(destination: Text("Edit Flow")) {
                    VStack(alignment: .leading) {
                        Text(flow.name).font(.headline)
                        Text("\(flow.steps.count) steps • \(flow.trigger.type.rawValue)").font(.caption).secondary()
                    }
                }
            }
            .onDelete { indices in
                flows.remove(atOffsets: indices)
            }

            Button(action: {
                flows.append(ConnectorFlow(name: "New Flow", trigger: FlowTrigger(type: .manual), steps: []))
            }) {
                Label("Add Flow", systemImage: "plus")
            }
        }
        .navigationTitle("Flow Builder")
    }
}
