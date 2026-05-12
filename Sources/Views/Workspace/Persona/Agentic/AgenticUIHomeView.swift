import SwiftUI
import FoundationModels

struct AgenticUIHomeView: View {
    @StateObject private var orchestrator = AgenticCoreOrchestrator.shared
    @StateObject private var capabilityService = AgenticCoreDeviceCapabilityService.shared
    @StateObject private var sessionManager = AgenticCoreSessionManager.shared
    @StateObject private var registry = WorkspaceAITools.shared
    @State private var showChat = false
    @State private var showDebug = false

    var body: some View {
        Group {
            if capabilityService.capability.isSupported {
                agenticContent
            } else {
                unavailableView
            }
        }
        .onAppear {
            _ = capabilityService.evaluate()
        }
    }

    // MARK: - Main Agentic Content

    private var agenticContent: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statusSection
                    quickActionsGrid
                    toolCategoriesSection
                }
                .padding()
            }
            .navigationTitle("Agentic AI")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showChat = true
                    } label: {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showDebug = true
                    } label: {
                        Image(systemName: "ant")
                    }
                }
            }
            .sheet(isPresented: $showChat) {
                AgenticUIChatView()
            }
            .sheet(isPresented: $showDebug) {
                AgenticUIDebugPanel()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse.byLayer)

            Text("Agentic Runtime")
                .font(.title.bold())

            Text("On-Device AI Execution Kernel")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Label("\(registry.tools.count) Tools", systemImage: "wrench.and.screwdriver")
                Label(capabilityService.capability.deviceClass, systemImage: "desktopcomputer")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    // MARK: - Status

    private var statusSection: some View {
        GroupBox {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                Text(orchestrator.executionState.rawValue.capitalized)
                    .font(.headline)

                Spacer()

                if orchestrator.executionState == .streaming {
                    ProgressView()
                }

                if orchestrator.iterationCount > 0 {
                    Text("Iteration \(orchestrator.iterationCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Execution Status", systemImage: "gauge.with.dots.needle.bottom.50percent")
        }
    }

    private var statusColor: Color {
        switch orchestrator.executionState {
        case .idle: return .gray
        case .preparing: return .yellow
        case .streaming: return .blue
        case .executingTool: return .orange
        case .completed: return .green
        case .failed: return .red
        case .interrupted: return .purple
        }
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            AgenticQuickActionCard(icon: "bubble.left.and.text.bubble.right", title: "Chat", subtitle: "Start conversation") {
                showChat = true
            }
            AgenticQuickActionCard(icon: "ant", title: "Debug", subtitle: "View traces") {
                showDebug = true
            }
            AgenticQuickActionCard(icon: "arrow.counterclockwise", title: "Reset", subtitle: "Clear session") {
                orchestrator.reset()
            }
            AgenticQuickActionCard(icon: "wrench.and.screwdriver", title: "Tools", subtitle: "\(registry.tools.count) registered") {
                showDebug = true
            }
        }
    }

    // MARK: - Tool Categories

    private var toolCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tool Engines")
                .font(.headline)

            ForEach(registry.categories, id: \.self) { category in
                let categoryTools = registry.tools(inCategory: category)
                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: iconForCategory(category))
                                .foregroundStyle(.tint)
                            Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(categoryTools.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.fill.tertiary, in: Capsule())
                        }
                        Text(categoryTools.map(\.name).joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Agentic AI Unavailable")
                .font(.title2.bold())

            if let reason = capabilityService.capability.requiredReason {
                Text(reason)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Text("Device: \(capabilityService.capability.deviceClass)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    // MARK: - Helpers

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "tasks": return "checklist"
        case "notes": return "note.text"
        case "calendar": return "calendar"
        case "mail": return "envelope"
        case "slides": return "rectangle.on.rectangle"
        case "spreadsheet": return "tablecells"
        case "workspace": return "folder"
        case "ai_transform": return "sparkles"
        case "media": return "photo"
        case "codegen": return "chevron.left.forwardslash.chevron.right"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Quick Action Card

private struct AgenticQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
