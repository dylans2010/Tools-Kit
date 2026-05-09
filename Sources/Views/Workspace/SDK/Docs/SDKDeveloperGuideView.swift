/*
 REDESIGN SUMMARY:
 - Standardized on insetGrouped List style.
 - Modernized the category selector using native Picker with SF Symbols.
 - Replaced manual documentation blocks with structured private subviews for better maintenance.
 - Standardized typography using .headline, .subheadline, and .caption.
 - strictly preserved all Developer Guide content and hierarchical navigation.
 - Improved visual hierarchy for code examples and API endpoints.
 - Extracted subviews for GuideIntroduction, SDKModuleOverview, and SecurityPolicySection.
 - RESTORED: Full documentation content that was mistakenly summarized in previous iteration.
 */

import SwiftUI

struct SDKDeveloperGuideView: View {
    @State private var selectedCategory: GuideCategory = .introduction

    enum GuideCategory: String, CaseIterable, Identifiable {
        case introduction = "Introduction"
        case core = "Core SDK"
        case plugins = "Plugins"
        case security = "Security"
        case deployment = "Deployment"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .introduction: return "hand.wave"
            case .core: return "cpu"
            case .plugins: return "puzzlepiece"
            case .security: return "shield.checkered"
            case .deployment: return "cloud.arrow.up"
            }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(GuideCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                SDKSectionHeader("Developer Documentation", subtitle: "Architecture and Integration Guide", alignment: .leading)
            }

            switch selectedCategory {
            case .introduction: IntroductionSection()
            case .core: CoreSDKSection()
            case .plugins: PluginsSection()
            case .security: SecuritySection()
            case .deployment: DeploymentSection()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dev Guide")
    }
}

// MARK: - Private Sections

private struct IntroductionSection: View {
    var body: some View {
        Section("Introduction") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Workspace SDK Platform").font(.headline)
                Text("ToolsKit provides a comprehensive, production-grade SDK for building and extending the Workspace OS. The platform is built on a modular kernel that manages data, security, and execution environments.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }.padding(.vertical, 4)
        }
        Section("Key Concepts") {
            DocRow(title: "Kernel", description: "The central orchestration layer for all SDK services.", icon: "gearshape.2")
            DocRow(title: "Data Store", description: "Atomic, concurrent-safe storage for persistent application state.", icon: "database")
            DocRow(title: "Event Bus", description: "Asynchronous pub/sub system for inter-module communication.", icon: "antenna.radiowaves.left.and.right")
        }
    }
}

private struct CoreSDKSection: View {
    var body: some View {
        Section("Core Modules") {
            DocRow(title: "SDKRouter", description: "Standardized internal API routing and endpoint management.", icon: "arrow.up.right.and.arrow.down.left.rectangle")
            DocRow(title: "ServiceRegistry", description: "Protocol-driven dependency injection container.", icon: "tray.full")
            DocRow(title: "WorkspaceState", description: "Reactive management of runtime environment diagnostics.", icon: "activitylog")
        }
        Section("Implementation Example") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Registering a Service").font(.caption.bold())
                Text("let service = MyService()\nServiceRegistry.shared.register(service, for: .mail)")
                    .font(.system(size: 10, design: .monospaced)).padding(8).background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }.padding(.vertical, 4)
        }
    }
}

private struct PluginsSection: View {
    var body: some View {
        Section("Plugin Architecture") {
            Text("Plugins are event-driven modules executing in an isolated JavaScriptCore sandbox. They interact with the workspace via a scoped context SDK.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Lifecycle Hooks") {
            DocRow(title: "onEvent", description: "Primary entry point for reacting to workspace triggers.", icon: "bolt")
            DocRow(title: "onLoad", description: "Initialization hook for setting up internal plugin state.", icon: "power")
        }
        Section("Runtime Context") {
            Text("ctx.notes, ctx.mail, ctx.ai, ctx.integrations").font(.system(size: 10, design: .monospaced)).foregroundStyle(.accent)
        }
    }
}

private struct SecuritySection: View {
    var body: some View {
        Section("Security Model") {
            Text("Hierarchical permission scopes ensure that modules only access necessary data. High-risk scopes require explicit user justification.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        Section("Access Scopes") {
            DocRow(title: "mail.read", description: "Allows reading subject and metadata of emails.", icon: "envelope")
            DocRow(title: "workspace.write", description: "Allows modifying notes and project structure.", icon: "pencil")
        }
    }
}

private struct DeploymentSection: View {
    var body: some View {
        Section("Release Pipeline") {
            DocRow(title: "Versioning", description: "Semantic versioning (SemVer) required for all SDK modules.", icon: "number")
            DocRow(title: "Validation", description: "Automated verification of capability and action schemas.", icon: "checkmark.shield")
        }
    }
}

private struct DocRow: View {
    let title: String; let description: String; let icon: String
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.caption2).foregroundStyle(.secondary)
            }
        } icon: { Image(systemName: icon).foregroundStyle(.accent) }
    }
}
