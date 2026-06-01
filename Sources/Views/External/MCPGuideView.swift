import SwiftUI

struct MCPGuideView: View {
    @State private var selectedCategory: GuideCategory = .introduction

    enum GuideCategory: String, CaseIterable, Identifiable {
        case introduction = "Introduction"
        case authentication = "Authentication"
        case configuration = "Advanced Configuration"
        case persona = "Persona AI Integration"
        case debugging = "Debugging & Logs"
        case protocolOverview = "Protocol Overview"
        case advancedRPC = "Advanced JSON-RPC"
        case security = "Security & Privacy"
        case customServers = "Custom Server Development"
        case useCases = "Use Cases"
        case bestPractices = "Best Practices"
        case production = "Production Deployment"
        case troubleshooting = "Troubleshooting"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .introduction: return "hand.wave"
            case .authentication: return "lock.shield"
            case .configuration: return "gearshape.2"
            case .persona: return "brain.head.profile"
            case .debugging: return "terminal"
            case .protocolOverview: return "network"
            case .advancedRPC: return "cpu"
            case .security: return "shield.checkered"
            case .customServers: return "hammer"
            case .useCases: return "lightbulb"
            case .bestPractices: return "star"
            case .production: return "shippingbox"
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
            case .configuration: ConfigurationSection()
            case .persona: PersonaIntegrationSection()
            case .debugging: DebuggingSection()
            case .protocolOverview: ProtocolOverviewSection()
            case .advancedRPC: AdvancedRPCSection()
            case .security: SecuritySection()
            case .customServers: CustomServersSection()
            case .useCases: UseCasesSection()
            case .bestPractices: BestPracticesSection()
            case .production: ProductionSection()
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

        Section(header: Text("JSON-RPC Lifecycle")) {
            Text("MCP uses JSON-RPC 2.0 over various transports (SSE, Stdio, WebSockets). Tools-Kit primarily uses SSE for remote servers.")
                .font(.caption2).foregroundStyle(.secondary)
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

private struct AdvancedRPCSection: View {
    var body: some View {
        Section(header: Text("Sampling Capabilities")) {
            Text("Sampling allows servers to request completions from the AI model via the client.")
                .font(.subheadline).foregroundStyle(.secondary)

            Text("""
            Method: sampling/createMessage
            Description: Server asks the AI for help.
            """)
            .font(.system(size: 10, design: .monospaced))
            .padding(8)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
        }

        Section(header: Text("Pagination & Streaming")) {
            GuideDefRow(name: "List Pagination", description: "Use 'nextCursor' in results to fetch more items.", icon: "arrow.right.circle")
            GuideDefRow(name: "Streaming Resources", description: "Subscribe to resource updates for real-time data flow.", icon: "wave.3.right")
        }
    }
}

private struct SecuritySection: View {
    var body: some View {
        Section(header: Text("Data Privacy")) {
            GuideDefRow(name: "On-Device Storage", description: "All MCP credentials are encrypted and stored in the iOS Keychain.", icon: "lock.icloud")
            GuideDefRow(name: "No Proxy", description: "Connections are made directly from your device to the server.", icon: "arrow.left.and.right.circle")
        }

        Section(header: Text("Access Control")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommended Security Headers:").font(.caption.bold())
                Text("""
                Strict-Transport-Security: max-age=31536000
                Content-Security-Policy: default-src 'none'
                """)
                .font(.system(size: 10, design: .monospaced))
                .padding(8)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

private struct CustomServersSection: View {
    var body: some View {
        Section(header: Text("Building with Python")) {
            Text("The official 'mcp' Python SDK is the fastest way to build servers.")
                .font(.subheadline).foregroundStyle(.secondary)

            Text("""
            from mcp.server import Server
            app = Server("weather-service")

            @app.tool()
            def get_weather(city: str) -> str:
                return f"Sunny in {city}"
            """)
            .font(.system(size: 10, design: .monospaced))
            .padding(8)
            .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
        }

        Section(header: Text("TypeScript / Node.js")) {
            Text("Use @modelcontextprotocol/sdk for TypeScript environments.")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct ProductionSection: View {
    var body: some View {
        Section(header: Text("Hosting Options")) {
            GuideDefRow(name: "Railway / Fly.io", description: "Excellent for persistent SSE servers.", icon: "cloud.fill")
            GuideDefRow(name: "Vercel / AWS Lambda", description: "Best for stateless HTTP-based tool execution.", icon: "bolt.fill")
        }

        Section(header: Text("Monitoring")) {
            GuideDefRow(name: "Health Checks", description: "Implement /health endpoint for uptime monitoring.", icon: "heart.pulse")
            GuideDefRow(name: "Usage Limits", description: "Apply rate limiting to prevent tool abuse.", icon: "gauge.medium")
        }
    }
}

private struct ConfigurationSection: View {
    var body: some View {
        Section(header: Text("Environment Variables")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Many MCP servers require environment variables for configuration (e.g., API keys, database URLs).")
                    .font(.caption2).foregroundStyle(.secondary)

                Text("""
                {
                  "env": {
                    "GITHUB_TOKEN": "your_token",
                    "DB_URL": "postgresql://..."
                  }
                }
                """)
                .font(.system(size: 10, design: .monospaced))
                .padding(8)
                .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 6))
            }
        }

        Section(header: Text("Custom Binaries")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("You can run local MCP servers written in Python, Node.js, or Go.")
                    .font(.caption2).foregroundStyle(.secondary)

                GuideDefRow(name: "Python", description: "python3 path/to/server.py", icon: "script.fill")
                GuideDefRow(name: "Node.js", description: "node path/to/server.js", icon: "dot.radiowaves.left.and.right")
            }
        }
    }
}

private struct PersonaIntegrationSection: View {
    var body: some View {
        Section(header: Text("AI Persona Integration")) {
            Text("Tools-Kit Persona AI can automatically use tools from your connected MCP servers.")
                .font(.subheadline).foregroundStyle(.secondary)

            GuideDefRow(name: "Discovery", description: "Persona scans all connected servers for available tools.", icon: "magnifyingglass")
            GuideDefRow(name: "Capability Injection", description: "Tool definitions are injected into the AI's system prompt.", icon: "plus.message")
            GuideDefRow(name: "Real-time Execution", description: "AI requests tool execution; Tools-Kit handles the networking.", icon: "bolt.horizontal.circle")
        }
    }
}

private struct DebuggingSection: View {
    var body: some View {
        Section(header: Text("Traffic Inspector")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Monitor raw JSON-RPC traffic to debug connection issues or tool execution errors.")
                    .font(.caption2).foregroundStyle(.secondary)

                Label("View Logs", systemImage: "list.bullet.rectangle.portrait")
                    .font(.subheadline.bold())
                Text("Open any server detail page and look for the 'Traffic Inspector' section.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }

        Section(header: Text("Common Status Codes")) {
            GuideDefRow(name: "-32700", description: "Parse Error: Invalid JSON received by the server.", icon: "exclamationmark.square")
            GuideDefRow(name: "-32601", description: "Method Not Found: The tool name is incorrect.", icon: "questionmark.square")
            GuideDefRow(name: "-32602", description: "Invalid Params: Check the tool's input schema.", icon: "xmark.square")
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
