import SwiftUI

struct ConnectorLogsView: View {
    @State private var logs: [ConnectorLogEntry] = [
        ConnectorLogEntry(timestamp: Date(), level: "INFO", message: "Connector Manager initialized."),
        ConnectorLogEntry(timestamp: Date().addingTimeInterval(-3600), level: "ERROR", message: "Failed to refresh OAuth token for GitHub Connector.")
    ]

    var body: some View {
        List {
            ForEach(logs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(log.level)
                            .font(.caption.bold())
                            .foregroundColor(log.level == "ERROR" ? .red : .blue)
                        Spacer()
                        Text(log.timestamp.formatted())
                            .font(.caption2)
                            .secondary()
                    }
                    Text(log.message).font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Connector Logs")
    }
}

struct ConnectorLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: String
    let message: String
}
