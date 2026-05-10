

import SwiftUI

struct ConnectorScopeView: View {
    @State var connector: ConnectorDefinition
    @StateObject private var policyEngine = SDKPolicyEngine.shared
    @StateObject private var manager = ConnectorManager.shared
    @State private var assignedScopes: Set<String> = []

    var body: some View {
        List {
            Section("Connector Identity") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(connector.name).font(.headline)
                    Text(connector.identifier).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
            }

            Section("Assign SDK Scopes") {
                if policyEngine.availableScopes().isEmpty {
                    ContentUnavailableView("No Scopes Available", systemImage: "shield.slash", description: Text("The policy engine has no registered scopes."))
                } else {
                    ForEach(policyEngine.availableScopes(), id: \.name) { scope in
                        Toggle(isOn: Binding(
                            get: { assignedScopes.contains(scope.name) },
                            set: { enabled in if enabled { assignedScopes.insert(scope.name) } else { assignedScopes.remove(scope.name) } }
                        )) {
                            HStack {
                                Text(scope.name).font(.subheadline)
                                Spacer()
                                Text(scope.riskLevel.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(riskColor(scope.riskLevel).opacity(0.1), in: Capsule())
                                    .foregroundStyle(riskColor(scope.riskLevel))
                            }
                        }
                    }
                }
            }

            Section {
                Button(action: saveScopes) {
                    Text("Save Scope Assignments")
                        .frame(maxWidth: .infinity).bold()
                }
                .buttonStyle(.borderedProminent)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connector Scopes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let mapped = connector.schema.mappings["sdkScopes"] {
                assignedScopes = Set(mapped.split(separator: ",").map { String($0) })
            }
        }
    }

    private func saveScopes() {
        connector.schema.mappings["sdkScopes"] = assignedScopes.sorted().joined(separator: ",")
        connector.updatedAt = Date()
        manager.updateConnector(connector)
    }

    private func riskColor(_ risk: SDKSecurityScopeDefinition.RiskLevel) -> Color {
        switch risk {
        case .high, .critical: return .red
        case .medium: return .orange
        case .low: return .green
        default: return .secondary
        }
    }
}
