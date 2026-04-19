import SwiftUI

struct DebugView: View {
    @StateObject private var manager = MeetingStateManager.shared
    @StateObject private var logger = DebugLogger.shared
    @AppStorage("meet.debug.apiKey") private var persistedAPIKey = ""

    var body: some View {
        Form {
            Section("Daily API Key") {
                SecureField("Daily API key", text: $persistedAPIKey)
                Button("Apply") {
                    Task { await manager.updateDeveloperAPIKey(persistedAPIKey) }
                }
            }

            Section("Session Traces") {
                if manager.debugSnapshot.mappings.isEmpty {
                    Text("No session mappings yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(manager.debugSnapshot.mappings) { mapping in
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

            Section("API Logs / WebRTC Events") {
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
            await manager.updateDeveloperAPIKey(persistedAPIKey)
            await manager.refreshDebugSnapshot()
        }
    }
}
