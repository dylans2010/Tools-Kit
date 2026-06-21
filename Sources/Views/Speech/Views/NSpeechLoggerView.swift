import SwiftUI

struct NSpeechLoggerView: View {
    @StateObject private var logStore = SDKLogStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if logStore.entries.isEmpty {
                        Text("No logs available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(logStore.entries) { entry in
                            LogEntryRow(entry: entry)
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
                    Button("Clear") {
                        logStore.clear()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LogEntryRow: View {
    let entry: SDKLogEntry

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dateFormatter.string(from: entry.timestamp))
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
}
