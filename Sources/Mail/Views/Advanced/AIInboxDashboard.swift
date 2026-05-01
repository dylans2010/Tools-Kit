import SwiftUI

/// Main dashboard for advanced AI-driven inbox management.
struct AIInboxDashboard: View {
    @StateObject private var viewModel = AIInboxDashboardViewModel()
    @State private var showingAutomationBuilder = false
    @State private var showingMemoryGraph = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                prioritySection
                insightsSection
                quickActionsSection
            }
            .padding()
        }
        .navigationTitle("AI Dashboard")
        .background(Color(uiColor: .systemGroupedBackground))
        .onDisappear { viewModel.cancelTasks() }
    }

    private var headerSection: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Inbox Intelligence")
                    .font(.headline)
                Text("AI is monitoring your communication to surface the most critical items.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var prioritySection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Priority Attention")
                    .font(.title3.bold())
                Spacer()
                NavigationLink("View Queue", destination: PriorityQueueView())
                    .font(.caption)
            }

            if viewModel.priorityThreads.isEmpty {
                Text("No urgent items detected.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            } else {
                ForEach(viewModel.priorityThreads.prefix(3)) { thread in
                    WorkspaceSurfaceCard {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(thread.subject)
                                    .font(.subheadline.bold())
                                Text(thread.snippet)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading) {
            Text("Automated Insights")
                .font(.title3.bold())

            WorkspaceSurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.insights.isEmpty {
                        Text("No active insights. Perform triage to generate.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.insights, id: \.self) { insight in
                            InsightRow(icon: "sparkles", text: insight)
                        }
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading) {
            Text("AI Actions")
                .font(.title3.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ActionCard(title: "Perform Triage", icon: "tray.full.fill", color: .blue) {
                    viewModel.performTriage()
                }
                ActionCard(title: "Clear Noise", icon: "sparkles.rectangle.stack", color: .purple) {
                    viewModel.clearNoise()
                }
                ActionCard(title: "Build Workflow", icon: "plus.square.dashed", color: .orange) {
                    showingAutomationBuilder = true
                }
                ActionCard(title: "Context Recall", icon: "brain.head.profile", color: .green) {
                    showingMemoryGraph = true
                }
            }
        }
        .navigationDestination(isPresented: $showingAutomationBuilder) {
            AutomationBuilderView()
        }
        .navigationDestination(isPresented: $showingMemoryGraph) {
            MemoryGraphViewer()
        }
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}
