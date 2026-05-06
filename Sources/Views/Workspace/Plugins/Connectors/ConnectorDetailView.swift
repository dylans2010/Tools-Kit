import SwiftUI

struct ConnectorDetailView: View {
    @ObservedObject var connector: AnyBaseConnectorWrapper
    @State private var showingAuth = false

    init(connector: any BaseConnector) {
        self.connector = AnyBaseConnectorWrapper(connector)
    }

    var body: some View {
        List {
            Section("Status") {
                LabeledContent("Current Status", value: connector.status.rawValue.capitalized)
                LabeledContent("Last Sync", value: "2 minutes ago")
            }

            Section("Actions") {
                Button("Test Connection") {
                    Task { try? await connector.testConnection() }
                }
                Button("Force Sync") {
                    Task { try? await connector.sync() }
                }
                Button("Configure Auth") {
                    showingAuth = true
                }
                Button("Disconnect", role: .destructive) {
                    connector.disconnect()
                }
            }

            Section("Activity Log") {
                ForEach(connector.activityLog) { event in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(event.message).font(.subheadline)
                            Text(event.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(connector.name)
        .sheet(isPresented: $showingAuth) {
            ConnectorAuthView(connector: connector)
        }
    }
}

// Type eraser for BaseConnector to use with @ObservedObject
class AnyBaseConnectorWrapper: ObservableObject, Identifiable {
    private let connector: any BaseConnector
    var id: UUID { connector.id }
    var name: String { connector.name }
    var authFields: [AuthField] { connector.authFields }

    @Published var status: ConnectorStatus
    @Published var activityLog: [ConnectorEvent]

    init(_ connector: any BaseConnector) {
        self.connector = connector
        self.status = connector.status
        self.activityLog = connector.activityLog

        // In a real app, you'd subscribe to changes if BaseConnector was a class with @Published
    }

    func authenticate(credentials: [String: String]) async throws {
        try await connector.authenticate(credentials: credentials)
        await MainActor.run { self.status = connector.status }
    }

    func sync() async throws {
        try await connector.sync()
    }

    func testConnection() async throws -> Bool {
        return try await connector.testConnection()
    }

    func disconnect() {
        connector.disconnect()
        self.status = connector.status
    }
}
