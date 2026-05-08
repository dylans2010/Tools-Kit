import SwiftUI

struct IDEDiagnosticsView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared
    @State private var filterSeverity: SDKRuntimeDiagnostic.Severity?
    @State private var selectedDiagnostic: SDKRuntimeDiagnostic?

    var filteredDiagnostics: [SDKRuntimeDiagnostic] {
        if let severity = filterSeverity {
            return state.diagnostics.filter { $0.severity == severity }
        }
        return state.diagnostics
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("System Diagnostics").font(.headline)
                            Text("Real-time SDK health monitoring and issue resolution.").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        SDKStatusPill("\(state.diagnostics.count) ISSUES", systemImage: "stethoscope", color: state.diagnostics.contains { $0.severity == .error } ? .red : .orange)
                    }

                    HStack(spacing: 8) {
                        filterButton(title: "All", severity: nil)
                        filterButton(title: "Errors", severity: .error)
                        filterButton(title: "Warnings", severity: .warning)

                        Spacer()

                        Button {
                            state.resolveAllConflicts()
                            state.recalculateDiagnostics()
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Fix All")
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                SDKSectionHeader("Health Monitor", subtitle: "Live system validation", systemImage: "bolt.heart.fill")
            }

            if filteredDiagnostics.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.green)
                        Text("System Healthy")
                            .font(.headline)
                        Text("No active diagnostics found for the current configuration.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(filteredDiagnostics) { diagnostic in
                    diagnosticRow(diagnostic)
                        .onTapGesture { state.open(node: diagnostic.node) }
                }
            }
        }
        .navigationTitle("Diagnostics")
    }

    private func filterButton(title: String, severity: SDKRuntimeDiagnostic.Severity?) -> some View {
        Button {
            filterSeverity = severity
        } label: {
            Text(title)
                .font(.caption2.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(filterSeverity == severity ? Color.primary.opacity(0.1) : Color.clear, in: Capsule())
                .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(filterSeverity == severity ? .primary : .secondary)
    }

    private func diagnosticRow(_ diagnostic: SDKRuntimeDiagnostic) -> some View {
        SDKModernCard(padding: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(diagnostic.severity == .error ? .red : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(diagnostic.node.title.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 3))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    Text(diagnostic.message)
                        .font(.system(size: 13, weight: .semibold))

                    Text(diagnostic.suggestion)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
