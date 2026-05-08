import SwiftUI

struct SDKCapabilitiesMatrixView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    private let capabilities = [
        "Runtime Config",
        "Dependency Planning",
        "Library Exports",
        "Connector Federation",
        "Scope Validation",
        "Pipeline Orchestration"
    ]

    var body: some View {
        List {
            Section("Capabilities Matrix") {
                ForEach(capabilities, id: \.self) { capability in
                    HStack {
                        Text(capability)
                        Spacer()
                        heatmap(usage: usageIntensity(for: capability))
                        runtimeImpactLabel(for: capability)
                    }
                }
            }

            Section("Conflict Markers") {
                if dependencyConflicts.isEmpty {
                    Text("No capability conflicts detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dependencyConflicts, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .navigationTitle("Capabilities")
    }

    private var dependencyConflicts: [String] {
        SDKDependencyConflictResolver().conflicts(in: state.dependencies)
    }

    private func usageIntensity(for capability: String) -> Int {
        switch capability {
        case "Library Exports": return state.libraries.reduce(0) { $0 + $1.exportedFunctions.count }
        case "Dependency Planning": return state.dependencies.count
        case "Scope Validation": return state.diagnostics.filter { $0.node == .scopes }.count
        default: return max(1, state.dependencies.count / 2)
        }
    }

    private func heatmap(usage: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < min(5, max(1, usage / 2)) ? .red.opacity(0.75) : .gray.opacity(0.25))
                    .frame(width: 14, height: 8)
            }
        }
    }

    private func runtimeImpactLabel(for capability: String) -> some View {
        let impact = usageIntensity(for: capability)
        return Text(impact > 6 ? "High" : impact > 2 ? "Medium" : "Low")
            .font(.caption2.bold())
            .foregroundStyle(impact > 6 ? .red : impact > 2 ? .orange : .green)
    }
}
