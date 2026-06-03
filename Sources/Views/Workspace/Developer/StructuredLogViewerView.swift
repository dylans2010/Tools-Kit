import SwiftUI

struct StructuredLogViewerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search logs...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()

            List {
                if store.structuredLogs.isEmpty {
                    Text("No logs found.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(store.structuredLogs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.level)
                                    .font(.system(size: 8, weight: .black))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(log.level == "ERROR" ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                    .foregroundStyle(log.level == "ERROR" ? .red : .blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                Text(log.category).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                                Spacer()
                                Text(log.timestamp.formatted(date: .omitted, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Text(log.message).font(.system(size: 11, design: .monospaced))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Structured Logs")
        .onAppear {
            if store.structuredLogs.isEmpty {
                store.saveStructuredLogs([
                    StructuredLog(level: "INFO", category: "Auth", message: "User session started", timestamp: Date()),
                    StructuredLog(level: "ERROR", category: "Network", message: "Request timed out: /v1/user", timestamp: Date().addingTimeInterval(-60))
                ])
            }
        }
    }
}
