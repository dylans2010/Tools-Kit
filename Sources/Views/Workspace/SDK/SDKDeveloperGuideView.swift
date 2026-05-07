import SwiftUI

struct SDKDeveloperGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("WorkspaceSDK Developer Guide")
                        .font(.largeTitle)
                        .bold()

                    Text("Architecture Overview")
                        .font(.title2)
                        .bold()

                    Text("The WorkspaceSDK is a modular developer platform. It follows a Kernel-based architecture where core services are managed by a central registry and exposed through a unified public interface.")
                }

                Group {
                    Text("1. Creating a Notebook Page")
                        .font(.headline)

                    CodeBlockView(code: """
let sdk = WorkspaceSDK.shared
try await sdk.notebooks.createNote(
    title: "Meeting Notes",
    content: "Action items: ..."
)
""")
                }

                Group {
                    Text("2. Sending Mail")
                        .font(.headline)

                    CodeBlockView(code: """
let sdk = WorkspaceSDK.shared
try await sdk.mail.sendMail(
    to: "client@example.com",
    subject: "Update",
    body: "The project is on track."
)
""")
                }

                Group {
                    Text("3. Subscribing to Events")
                        .font(.headline)

                    CodeBlockView(code: """
let sdk = WorkspaceSDK.shared
sdk.events.subscribe(to: "mail.sent") { event in
    print("Mail sent to: \\(event.payload["to"] ?? "")")
}
""")
                }

                Group {
                    Text("4. Building a Plugin")
                        .font(.headline)

                    CodeBlockView(code: """
struct MyPlugin: SDKPlugin {
    let id = UUID()
    let name = "Logger Plugin"
    let identifier = "com.myapp.logger"
    let requiredScopes: [SDKPermissionManager.PermissionScope] = [.mailRead]

    func execute(action: String, parameters: [String: Any]) async throws -> Any? {
        print("Action executed: \\(action)")
        return nil
    }
}
""")
                }
            }
            .padding()
        }
        .navigationTitle("Developer Guide")
    }
}

struct CodeBlockView: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.system(.body, design: .monospaced))
            .padding()
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}
