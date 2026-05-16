import SwiftUI

struct AgenticUIHomeView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var sessionManager = AgenticCoreSessionManager.shared
    @StateObject private var toolRegistry = WorkspaceAITools.shared
    @State private var prompt: String = ""
    @State private var selectedTab: AgenticTab = .chat

    enum AgenticTab: String, CaseIterable {
        case chat = "Chat"
        case actions = "Actions"
        case workspace = "Workspace"
        case debug = "Debug"

        var icon: String {
            switch self {
            case .chat: return "bubble.left.and.text.bubble.right"
            case .actions: return "bolt.circle"
            case .workspace: return "folder.badge.gearshape"
            case .debug: return "ladybug"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabSelector

                TabView(selection: $selectedTab) {
                    AgenticUIChatView()
                        .tag(AgenticTab.chat)

                    AgenticUIActionStreamView()
                        .tag(AgenticTab.actions)

                    AgenticUIWorkspaceInspectorView()
                        .tag(AgenticTab.workspace)

                    AgenticUIDebugPanel()
                        .tag(AgenticTab.debug)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Agentic System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    stateIndicator
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Reset System") {
                            orchestrator.reset()
                        }
                        Button("Re-analyze Workspace") {
                            Task { await reanalyze() }
                        }
                        Button("Regenerate Tools") {
                            Task { _ = await toolRegistry.regenerateTools() }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await initialSetup()
            }
        }
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AgenticTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.accentColor : Color(.systemGray5))
                        .foregroundStyle(selectedTab == tab ? .white : .primary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var stateIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)
            Text(orchestrator.state.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var stateColor: Color {
        switch orchestrator.state {
        case .idle: return .gray
        case .checkingAvailability: return .orange
        case .analyzingWorkspace: return .blue
        case .generatingTools: return .purple
        case .streaming: return .green
        case .executingTool: return .cyan
        case .completed: return .green
        case .error: return .red
        }
    }

    private func initialSetup() async {
        guard orchestrator.workspaceGraph == nil else { return }
        await reanalyze()
    }

    private func reanalyze() async {
        do {
            let graph = try await AgenticWorkspaceAnalyzer.shared.analyzeWorkspace()
            orchestrator.workspaceGraph = graph
            _ = await toolRegistry.generateTools(from: graph)
        } catch {
            sessionManager.addDiagnostic(
                level: .error,
                message: "Initial workspace analysis failed: \(error.localizedDescription)",
                component: "HomeView"
            )
        }
    }
}
