import SwiftUI

struct IDEDiagnosticsView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("System Health").font(.headline)
                            Text("Real-time SDK validation and diagnostic reporting.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("\(state.diagnostics.count) ISSUES", systemImage: "stethoscope", color: state.diagnostics.contains { $0.severity == .error } ? .red : .orange)
                    }

                    if !state.diagnostics.isEmpty {
                        Button {
                            // Call resolveAllConflicts if available, otherwise manual fix
                            resolveAll()
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Resolve All Issues")
                            }
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(Color(.systemBackground))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Diagnostics", subtitle: "Integrity monitoring", systemImage: "heart.text.square.fill")
            }

            Section("Runtime Reports") {
                if state.diagnostics.isEmpty {
                    ContentUnavailableView("All Systems Go", systemImage: "checkmark.circle.fill", description: Text("No issues detected in the current SDK configuration."))
                        .foregroundStyle(.green)
                } else {
                    ForEach(state.diagnostics) { diagnostic in
                        diagnosticRow(for: diagnostic)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Diagnostics")
    }

    private func diagnosticRow(for diagnostic: SDKRuntimeDiagnostic) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(diagnostic.severity == .error ? .red : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(diagnostic.message)
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Text(diagnostic.node.title)
                        .font(.system(size: 9, weight: .black))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1), in: Capsule())
                }

                Text(diagnostic.suggestion)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Button("Fix Issue") {
                    state.open(node: diagnostic.node)
                }
                .font(.caption.bold())
                .buttonStyle(.borderless)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
    }

    private func resolveAll() {
        // Attempting to resolve via state recalculation or known fixes
        state.recalculateDiagnostics()
    }
}
