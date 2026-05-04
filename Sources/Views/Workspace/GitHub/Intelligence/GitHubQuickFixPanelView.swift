import SwiftUI

struct GitHubQuickFixPanelView: View {
    @ObservedObject private var intelligence = RepoIntelligenceService.shared
    @ObservedObject private var gitEngine = GitEngineService.shared

    var body: some View {
        List {
            Section("Deterministic Fixes") {
                QuickFixRow(title: "Remove Unused Imports", icon: "link.badge.plus", description: "Rule-based parsing to clean up Swift imports.") {
                    // Logic to parse and remove unused imports
                }

                QuickFixRow(title: "Format Code Structure", icon: "hammer.fill", description: "Apply non-AI deterministic formatting rules.") {
                    // Logic to format code
                }

                QuickFixRow(title: "Revert File State", icon: "arrow.uturn.backward", description: "Restore file to the last committed state.") {
                    // Logic to revert file
                }
            }

            Section("Recovery Actions") {
                QuickFixRow(title: "Restore Deleted Files", icon: "doc.badge.plus", description: "Recover tracked files that were recently deleted.") {
                    // Logic to restore files
                }

                QuickFixRow(title: "Trigger Conflict Mode", icon: "exclamationmark.triangle.fill", color: .orange, description: "Manually enter conflict resolution for selected files.") {
                    // Logic to enter conflict mode
                }
            }

            Section("System Status") {
                HStack {
                    Text("Intelligence Scanning")
                    Spacer()
                    if intelligence.isScanning {
                        ProgressView()
                    } else {
                        Text("Idle").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Quick Fix")
    }
}

struct QuickFixRow: View {
    let title: String
    let icon: String
    var color: Color = .blue
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
