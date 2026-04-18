import Daily

#if DEBUG
import SwiftUI

struct DebugView: View {
    @StateObject private var controller = MeetSessionController.shared
    @StateObject private var logger = DebugLogger.shared
    @State private var apiKeyInput = ""

    var body: some View {
        Form {
            Section("API Key (In-Memory)") {
                SecureField("Daily API key", text: $apiKeyInput)
                Button("Apply") {
                    Task { await controller.updateDeveloperAPIKey(apiKeyInput) }
                }
            }

            Section("Session Inspection") {
                if controller.debugSnapshot.mappings.isEmpty {
                    Text("No session mappings yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(controller.debugSnapshot.mappings) { mapping in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Meeting ID: \(mapping.meetingId)")
                                .font(.subheadline.bold())
                            Text("Room: \(mapping.roomName)")
                                .font(.caption)
                            Text("Session: \(mapping.sessionId)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("API Logs") {
                if logger.entries.isEmpty {
                    Text("No logs yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(logger.entries) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("[\(entry.category)] \(entry.message)")
                                .font(.caption)
                            Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button("Clear Logs", role: .destructive) {
                    logger.clear()
                }
            }
        }
        .navigationTitle("Meet Debug Console")
        .task {
            await controller.refreshDebugSnapshot()
        }
    }
}
#endif
