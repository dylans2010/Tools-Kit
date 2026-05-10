/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Replaced manual pills and headers with native Section titles and LabeledContent.
 - Modernized diagnostic rows using a private struct DiagnosticItemRow with semantic severity icons.
 - Standardized status coloring using semantic .red, .orange, and .green.
 - strictly preserved all SDKRuntimeWorkspaceState diagnostics, recalculation, and navigation logic.
 - Implemented ContentUnavailableView for 'All Systems Go' states.
 - Standardized the 'Resolve All' button with a prominent prominent style.
 */

import SwiftUI

struct IDEDiagnosticsView: View {
    @StateObject private var state = SDKRuntimeWorkspaceState.shared

    var body: some View {
        List {
            Section("Status Monitoring") {
                LabeledContent("Active Issues") {
                    Text("\(state.diagnostics.count)")
                        .monospaced().bold()
                        .foregroundStyle(state.diagnostics.contains { $0.severity == .error } ? Color.red : Color.orange)
                }

                if !state.diagnostics.isEmpty {
                    Button(action: { state.recalculateDiagnostics() }) {
                        Label("Resolve All Issues", systemImage: "wand.and.stars")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Section("Runtime Reports") {
                if state.diagnostics.isEmpty {
                    ContentUnavailableView(
                        "All Systems Go",
                        systemImage: "checkmark.circle",
                        description: Text("No issues detected in the current SDK configuration.")
                    )
                    .foregroundStyle(.green)
                } else {
                    ForEach(state.diagnostics) { diagnostic in
                        DiagnosticItemRow(diagnostic: diagnostic) {
                            state.open(node: diagnostic.node)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Private Subviews

private struct DiagnosticItemRow: View {
    let diagnostic: SDKRuntimeDiagnostic
    let onFix: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: diagnostic.severity == .error ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(diagnostic.severity == .error ? Color.red : Color.orange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(diagnostic.message).font(.subheadline.bold())
                        Spacer()
                        Text(diagnostic.node.title)
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.05), in: Capsule())
                    }

                    Text(diagnostic.suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Jump to Fix", action: onFix)
                .font(.caption2.bold())
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .padding(.leading, 32)
        }
        .padding(.vertical, 4)
    }
}
