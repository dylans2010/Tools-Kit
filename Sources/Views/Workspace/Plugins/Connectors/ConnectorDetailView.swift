import SwiftUI

struct ConnectorDetailView<T: BaseConnector>: View {
    @ObservedObject var connector: T
    @State private var showingAuth = false

    var body: some View {
        List {
            Section("Status") {
                HStack {
                    Text("Connection Status")
                    Spacer()
                    Text(connector.status.rawValue.capitalized)
                        .foregroundStyle(connector.status == .connected ? .green : .red)
                }

                if let lastEvent = connector.activityLog.first {
                    HStack {
                        Text("Last Activity")
                        Spacer()
                        Text(lastEvent.timestamp.formatted(.relative(presentation: .numeric)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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
                ForEach(connector.activityLog.prefix(20)) { event in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(event.level.rawValue.uppercased())
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(color(for: event.level))
                            Spacer()
                            Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(event.message)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(connector.name)
        .sheet(isPresented: $showingAuth) {
            ConnectorAuthView(connector: connector)
        }
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        case .debug: return .gray
        }
    }
}
