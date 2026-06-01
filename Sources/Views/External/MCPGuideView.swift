import SwiftUI

struct MCPGuideView: View {
    @State private var selectedCategory: GuideCategory = .introduction

    enum GuideCategory: String, CaseIterable, Identifiable {
        case introduction = "Introduction"
        case authentication = "Authentication"
        case useCases = "Use Cases"
        case protocolOverview = "Protocol Overview"
        case bestPractices = "Best Practices"
        case troubleshooting = "Troubleshooting"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .introduction: return "hand.wave"
            case .authentication: return "lock.shield"
            case .useCases: return "lightbulb"
            case .protocolOverview: return "network"
            case .bestPractices: return "star"
            case .troubleshooting: return "wrench.and.screwdriver"
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
                SDKSectionHeader("MCP Guide", subtitle: "Model Context Protocol Integration & Setup", alignment: .leading)
            }

            switch selectedCategory {
            case .introduction: IntroductionSection()
            case .authentication: AuthenticationSection()
            case .useCases: UseCasesSection()
            case .protocolOverview: ProtocolOverviewSection()
            case .bestPractices: BestPracticesSection()
            case .troubleshooting: TroubleshootingSection()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("MCP Guide")
    }
}

// MARK: - Sections

private struct IntroductionSection: View {
    var body: some View {
        Section(header: Text("Model Context Protocol")) {
            VStack(alignment: .leading, spacing: 12) {
                Text("What is MCP?").font(.headline)
                Text("The Model Context Protocol (MCP) is an open standard that enables AI models to safely and securely interact with external tools and data sources. It provides a standardized way for servers to expose capabilities to AI clients like Tools-Kit.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }.padding(.vertical, 4)
        }
        Section(header: Text("Core Concepts")) {
            GuideDefRow(name: "Client", description: "The AI application (Tools-Kit) that initiates connections", icon: "iphone")
            GuideDefRow(name: "Server", description: "The service providing tools and data (e.g., GitHub, Google, Local Scripts)", icon: "server.rack")
            GuideDefRow(name: "Tools", description: "Executable functions the AI can call to perform actions", icon: "wrench")
            GuideDefRow(name: "Resources", description: "Data sources the AI can read to gain context", icon: "doc.text")
            GuideDefRow(name: "Prompts", description: "Template-based instructions provided by the server", icon: "bubble.left.and.exclamationmark.bubble.right")
        }
    }
}

private struct AuthenticationSection: View {
    var body: some View {
        Section(header: Text("Authentication Methods")) {
            Text("Tools-Kit supports multiple authentication schemes to securely connect to MCP servers.")
                .font(.subheadline).foregroundStyle(.secondary)
        }

        Section(header: Text("API Key")) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Setup", systemImage: "key.fill").font(.caption.bold())
                Text("Commonly used for simple web services. You provide a header name (e.g., X-API-Key) and the secret key.")
                    .font(.caption2).foregroundStyle(.secondary)

                Text("""
                Header: X-API-Key
                Value: your_secret_key_here
                """)
                .font(.system(size: 10, design: .monospaced))
                .padding(8)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }
        }

        Section(header: Text("Bearer Token")) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Setup", systemImage: "person.badge.key").font(.caption.bold())
                Text("Standard for modern APIs. Tools-Kit automatically adds the 'Bearer' prefix to your token.")
                    .font(.caption2).foregroundStyle(.secondary)

                Text("""
                Authorization: Bearer <your_token>
                """)
                .font(.system(size: 10, design: .monospaced))
                .padding(8)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }
        }

        Section(header: Text("OAuth2 (Auth Code + PKCE)")) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Setup", systemImage: "safari").font(.caption.bold())
                Text("Most secure for user-facing integrations. Requires an interactive login flow.")
                    .font(.caption2).foregroundStyle(.secondary)

                GuideDefRow(name: "Redirect URI", description: "toolskit://oauth/callback", icon: "link")
                GuideDefRow(name: "Scopes", description: "Define necessary permissions (e.g., repo, user)", icon: "checklist")
            }
        }

        Section(header: Text("Custom Headers")) {
            Text("For unique requirements, you can define multiple arbitrary header key-value pairs.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct UseCasesSection: View {
    var body: some View {
        Section(header: Text("Common Use Cases")) {
            GuideDefRow(name: "Local Development", description: "Connect to a local server to let the AI run shell scripts or access your local file system.", icon: "terminal")
            GuideDefRow(name: "Data Analysis", description: "Bridge to a SQL database or CSV processor to analyze large datasets directly.", icon: "chart.bar.xaxis")
            GuideDefRow(name: "API Integration", description: "Connect to specialized services like GitHub, Slack, or Jira without custom SDKs.", icon: "link")
            GuideDefRow(name: "Home Automation", description: "Control smart home devices via a local MCP bridge.", icon: "house")
        }
    }
}

private struct ProtocolOverviewSection: View {
    var body: some View {
        Section(header: Text("How it Works")) {
            VStack(alignment: .leading, spacing: 10) {
                protocolStep(1, "Discovery", "Client connects and asks 'What can you do?'")
                protocolStep(2, "Capabilities", "Server responds with a list of Tools and Resources.")
                protocolStep(3, "Execution", "AI decides to use a tool; Client sends a JSON-RPC request.")
                protocolStep(4, "Response", "Server executes the logic and returns JSON data.")
            }
            .padding(.vertical, 4)
        }

        Section(header: Text("JSON-RPC Example")) {
            Text("""
            {
              "jsonrpc": "2.0",
              "method": "tools/call",
              "params": {
                "name": "get_weather",
                "arguments": { "city": "San Francisco" }
              },
              "id": 1
            }
            """)
            .font(.system(size: 10, design: .monospaced))
            .padding(8)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func protocolStep(_ num: Int, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(num)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                Text(desc).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct BestPracticesSection: View {
    var body: some View {
        Section(header: Text("Security & Efficiency")) {
            GuideDefRow(name: "Least Privilege", description: "Only grant the minimum necessary API scopes for the task.", icon: "shield.lefthalf.filled")
            GuideDefRow(name: "Local First", description: "Prefer local MCP servers for sensitive data to keep it on-device.", icon: "antenna.radiowaves.left.and.right")
            GuideDefRow(name: "Clear Descriptions", description: "Ensure server tool descriptions are detailed so the AI knows when to use them.", icon: "text.alignleft")
            GuideDefRow(name: "Timeout Management", description: "Keep tool execution times under 30s to prevent AI timeouts.", icon: "timer")
        }
    }
}

private struct TroubleshootingSection: View {
    var body: some View {
        Section(header: Text("Common Issues")) {
            VStack(alignment: .leading, spacing: 12) {
                issueRow("Connection Refused", "Ensure the server is running and the URL is correct (check http vs https).")
                issueRow("401 Unauthorized", "Check your API Key or Token. Ensure headers match the server's expectation.")
                issueRow("Tool Not Found", "The server may need a restart or refresh to broadcast new tools.")
                issueRow("JSON Parse Error", "Verify the server is returning valid JSON-RPC 2.0 responses.")
            }
            .padding(.vertical, 4)
        }
    }

    private func issueRow(_ title: String, _ desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline.bold()).foregroundStyle(.red)
            Text(desc).font(.caption).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Reusable Components (Matching SDKDeveloperGuideView)

private struct GuideDefRow: View {
    let name: String
    let description: String
    let icon: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.subheadline.bold())
                Text(description).font(.caption2).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon).foregroundStyle(Color.accentColor)
        }
    }
}
