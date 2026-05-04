import SwiftUI

/// Main dashboard for advanced AI-driven inbox management.
struct AIInboxDashboard: View {
    @StateObject private var viewModel = AIInboxDashboardViewModel()
    @State private var showingAutomationBuilder = false
    @State private var showingMemoryGraph = false
    @State private var showingWorkflowMonitor = false

    var body: some View {
        ZStack {
            Color.workspaceBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection

                    if viewModel.isTriageActive {
                        triageLoadingView
                    } else {
                        prioritySection
                        insightsSection
                    }

                    quickActionsSection
                }
                .padding()
            }
        }
        .navigationTitle("Inbox Intelligence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingWorkflowMonitor = true
                } label: {
                    Image(systemName: "gauge.with.needle")
                }
            }
        }
        .sheet(isPresented: $showingWorkflowMonitor) {
            NavigationStack {
                WorkflowExecutionMonitor()
            }
        }
        .onAppear { viewModel.performTriage() }
        .onDisappear { viewModel.cancelTasks() }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Intelligence Overview")
                    .font(.title2.bold())
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(LinearGradient(colors: [.aiGradientStart, .aiGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            Text("AI is monitoring your communication to surface critical items and automate workflows.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var triageLoadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("AI is performing deep triage...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(Color.workspaceSurface.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))
    }

    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            priorityHeader

            if viewModel.priorityThreads.isEmpty {
                emptyPriorityState
            } else {
                priorityThreadList
            }
        }
    }

    private var priorityHeader: some View {
        HStack {
            Label("Priority Attention", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Spacer()
            NavigationLink("Full Queue", destination: PriorityQueueView())
                .font(.caption.bold())
                .foregroundStyle(.blue)
        }
    }

    private var emptyPriorityState: some View {
        Text("All quiet for now. No urgent items detected.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 30)
    }

    private var priorityThreadList: some View {
        ForEach(viewModel.priorityThreads.prefix(3)) { thread in
            NavigationLink(destination: MailThreadView(viewModel: MailViewModel(), email: EmailMessage(uid: Int(thread.messages.last?.id ?? "0") ?? 0, subject: thread.subject, sender: thread.messages.last?.from ?? "Unknown Sender", date: thread.lastMessageDate, preview: thread.messages.last?.body ?? "", isRead: thread.isRead, body: thread.messages.last?.body, htmlBody: thread.messages.last?.htmlBody, attachments: []))) {
                priorityThreadRow(thread)
            }
            .buttonStyle(.plain)
        }
    }

    private func priorityThreadRow(_ thread: MailThread) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(thread.subject)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                Text("\(Int((thread.priorityScore ?? 0.8) * 100))")
                    .font(.system(size: 10, weight: .bold))
                    .padding(4)
                    .background(Color.orange.opacity(0.2), in: Circle())
                    .foregroundStyle(.orange)
            }
            Text(thread.messages.last?.body.prefix(100) ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color.workspaceSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Automated Insights", systemImage: "brain.head.profile")
                .font(.headline)
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 12) {
                if viewModel.insights.isEmpty {
                    Text("Triage your inbox to generate intelligence.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.purple)
                                .padding(.top, 2)
                            Text(insight)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Actions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
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

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .padding()
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
