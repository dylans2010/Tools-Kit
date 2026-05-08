import SwiftUI

struct SDKDeveloperGuideView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("WorkspaceSDK Architecture")
                        .font(.headline)
                    Text("The SDK is organized into several production-grade layers to ensure scalability, security, and persistence.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        ArchitectureLayerInfo(name: "Kernel Layer", description: "Bootstrap, lifecycle, and service orchestration (WorkspaceSDKKernel.swift).")
                        ArchitectureLayerInfo(name: "Service Layer", description: "Protocol-driven dependency injection (ServiceContainer.swift).")
                        ArchitectureLayerInfo(name: "Data Layer", description: "Offline-first persistence with SDKDatabase and SDKQueryEngine.")
                        ArchitectureLayerInfo(name: "API Layer", description: "Structured endpoint routing (SDKRouter.swift).")
                        ArchitectureLayerInfo(name: "Security Layer", description: "Scoped permission management (SDKPermissionManager.swift).")
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Platform Architecture")
            }

            Section {
                GuideCodeBlock(
                    title: "Initialize SDK",
                    description: "Boot the kernel and all services.",
                    code: "await WorkspaceSDK.shared.initialize()"
                )

                GuideCodeBlock(
                    title: "Creating a Note",
                    description: "Create a new notebook with a default page.",
                    code: """
let sdk = WorkspaceSDK.shared
let notebook = try sdk.notebooks.createNotebook(title: "My Project Notes")
print("Notebook created: \\(notebook.id)")
"""
                )

                GuideCodeBlock(
                    title: "Sending Mail",
                    description: "Send a secure SMTP email through the SDK.",
                    code: """
let sdk = WorkspaceSDK.shared
try await sdk.mail.send(
    to: "jules@example.com",
    subject: "SDK Implementation",
    body: "The WorkspaceSDK is now fully production-grade."
)
"""
                )

                GuideCodeBlock(
                    title: "Subscribing to Events",
                    description: "Listen for real-time system events.",
                    code: """
let sdk = WorkspaceSDK.shared
let cancellable = sdk.events.subscribe(channel: "notebooks") { event in
    if event.name == "notebook.created" {
        print("A new notebook was created: \\(event.data[\\"title\\"] ?? \\"\\")")
    }
}
"""
                )
            } header: {
                Text("Swift Implementation Examples")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Development Rules")
                        .font(.subheadline.bold())
                    Text("1. Always use @ServiceInjected for cross-module dependencies.")
                    Text("2. Enforce permission scopes before executing privileged actions.")
                    Text("3. Persist all state changes through SDKDataStore.")
                    Text("4. Emit events for all significant state changes.")
                }
                .font(.caption)
                .padding(.vertical, 4)
            } header: {
                Text("Best Practices")
            }
        }
        .navigationTitle("Developer Guide")
    }
}

struct ArchitectureLayerInfo: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).font(.caption.bold())
            Text(description).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct GuideCodeBlock: View {
    let title: String
    let description: String
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.bold())
            Text(description).font(.caption).foregroundStyle(.secondary)
            
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        }
        .padding(.vertical, 4)
    }
}
