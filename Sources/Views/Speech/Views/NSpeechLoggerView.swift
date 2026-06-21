import SwiftUI

struct NSpeechLoggerView: View {
    @StateObject private var logStore = SDKLogStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if logStore.entries.isEmpty {
                        Text("No Logs Available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(logStore.entries, id: \.id) { entry in
                            SpeechLogEntryRow(entry: entry)
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Speech Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button("Clear") {
                            logStore.clear()
                        }
                        .foregroundColor(.red)

                        Button {
                            copyLogsToClipboard()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }

                        ShareLink(item: exportLogsAsJSON(), preview: SharePreview("NSpeechLogs.json")) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func copyLogsToClipboard() {
        let logText = logStore.entries.map { "[\($0.timestamp)] [\($0.level.rawValue.uppercased())] [\($0.source ?? "Unknown")] \($0.message)" }.joined(separator: "\n")
        UIPasteboard.general.string = logText
    }

    private func exportLogsAsJSON() -> URL {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("NSpeechLogs.json")
        do {
            let data = try JSONEncoder().encode(logStore.entries)
            try data.write(to: fileURL)
        } catch {
            print("Failed to export logs: \(error)")
        }
        return fileURL
    }
}

/// Marked `private` so this can never collide with another `LogEntryRow`
/// type elsewhere in the module (e.g. the MCP traffic log view).
private struct SpeechLogEntryRow: View {
    let entry: SDKLogEntry

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Self.dateFormatter.string(from: entry.timestamp))
                    .font(.caption2.monospaced())
                    .foregroundColor(.secondary)

                if let source = entry.source {
                    Text(source)
                        .font(.caption2.bold())
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                if let errorCode = entry.errorCode {
                    Text("Error: \(errorCode)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(4)
                }

                Text(entry.level.rawValue.uppercased())
                    .font(.caption2.bold())
                    .foregroundColor(entry.level == .error ? .red : .green)
            }

            Text(entry.message)
                .font(.subheadline.monospaced())
                .foregroundColor(entry.level == .error ? .red : .primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NSpeechLoggerView()
        .onAppear {
            if SDKLogStore.shared.entries.isEmpty {
                SDKLogStore.shared.entries = [
                    SDKLogEntry(
                        id: UUID(),
                        timestamp: Date(),
                        level: .info,
                        message: "Preview Log Entry",
                        source: "Preview",
                        errorCode: nil
                    )
                ]
            }
        }
}
