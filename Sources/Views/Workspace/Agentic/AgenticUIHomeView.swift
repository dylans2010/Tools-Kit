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
                AgenticUIChatView()
            }
            .navigationTitle("Foundation Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    stateIndicator
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Reset Chat") {
                            orchestrator.reset()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
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

}
