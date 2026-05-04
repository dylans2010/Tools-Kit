import SwiftUI

struct GitHubToolDashboardView: View {
    let owner: String
    let repo: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                VStack(alignment: .leading, spacing: 12) {
                    Text("Core Workflow")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        IntelligenceToolCard(title: "Code Editor", icon: "square.and.pencil", color: .blue, destination: AnyView(GitHubCodeEditorWorkspaceView(filePath: "Sources/App.swift")))
                        IntelligenceToolCard(title: "Staging Area", icon: "tray.and.arrow.down.fill", color: .green, destination: AnyView(GitHubStagingAreaView()))
                        IntelligenceToolCard(title: "Command Center", icon: "terminal.fill", color: .black, destination: AnyView(GitHubCommandCenterView()))
                        IntelligenceToolCard(title: "Change Review", icon: "checkmark.shield.fill", color: .orange, destination: AnyView(GitHubChangeReviewerView()))
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Intelligence & Analysis")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        IntelligenceToolCard(title: "Quick Fix", icon: "wand.and.stars", color: .purple, destination: AnyView(GitHubQuickFixPanelView()))
                        IntelligenceToolCard(title: "Conflict Res", icon: "exclamationmark.triangle.fill", color: .red, destination: AnyView(GitHubConflictResolutionView()))
                        IntelligenceToolCard(title: "Hotspots", icon: "flame.fill", color: .red, destination: AnyView(GitHubHotspotDetectorView()))
                        IntelligenceToolCard(title: "Refactor Plan", icon: "map.fill", color: .indigo, destination: AnyView(GitHubRefactorPlannerView()))
                        IntelligenceToolCard(title: "Dependency", icon: "node.italic", color: .teal, destination: AnyView(GitHubDependencyDebuggerView()))
                        IntelligenceToolCard(title: "Sync Status", icon: "arrow.triangle.2.circlepath", color: .blue, destination: AnyView(GitHubSyncStatusDashboardView()))
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Release & Recovery")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        IntelligenceToolCard(title: "Release Builder", icon: "tag.fill", color: .green, destination: AnyView(GitHubReleaseBuilderView()))
                        IntelligenceToolCard(title: "File Recovery", icon: "arrow.clockwise.icloud.fill", color: .blue, destination: AnyView(GitHubFileRecoveryView()))
                        IntelligenceToolCard(title: "Snapshots", icon: "camera.fill", color: .gray, destination: AnyView(GitHubWorkspaceSnapshotView()))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Intelligence Module")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(owner)/\(repo)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("GitHub OS")
                .font(.title2.bold())
        }
        .padding(.horizontal)
    }
}

struct IntelligenceToolCard: View {
    let title: String
    let icon: String
    let color: Color
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
