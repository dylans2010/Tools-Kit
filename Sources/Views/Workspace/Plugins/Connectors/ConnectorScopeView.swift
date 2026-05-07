import SwiftUI

struct ConnectorScopeView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var policyEngine = SDKPolicyEngine.shared
    @StateObject private var manager = ConnectorManager.shared
    @State private var assignedScopes: Set<String> = []

    var body: some View {
        List {
            Section("Connector") {
                Text(connector.name)
                Text(connector.identifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Assign SDK Scopes") {
                ForEach(policyEngine.availableScopes(), id: \.name) { scope in
                    Toggle(isOn: Binding(
                        get: { assignedScopes.contains(scope.name) },
                        set: { enabled in
                            if enabled {
                                assignedScopes.insert(scope.name)
                            } else {
                                assignedScopes.remove(scope.name)
                            }
                        }
                    )) {
                        HStack {
                            Text(scope.name).font(.caption)
                            Spacer()
                            Text(scope.riskLevel.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundStyle(scope.riskLevel == .high || scope.riskLevel == .critical ? .red : .secondary)
                        }
                    }
                }
            }

            Section {
                Button("Save Scope Assignments") {
                    connector.schema.mappings["sdkScopes"] = assignedScopes.sorted().joined(separator: ",")
                    connector.updatedAt = Date()
                    manager.updateConnector(connector)
                }
            }
        }
        .navigationTitle("Connector Scopes")
        .onAppear {
            if let mapped = connector.schema.mappings["sdkScopes"] {
                assignedScopes = Set(mapped.split(separator: ",").map { String($0) })
            }
        }
    }
}
