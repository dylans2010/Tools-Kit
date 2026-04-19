import SwiftUI

struct DebugView: View {
    @ObservedObject var controller: MeetSessionController
    @AppStorage("debug.dailyAPIKey") private var apiKey = ""
    @StateObject private var logger = DebugLogger.shared

    var body: some View {
        List {
            Section("API Configuration") {
                SecureField("Daily API Key", text: $apiKey)

                Button("Clear Key", role: .destructive) {
                    apiKey = ""
                }
            }

            Section("Crypto Test") {
                Button("Run Encryption Round-trip") {
                    testCrypto()
                }
            }

            Section("Live Logs") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(logger.entries.prefix(200)) { entry in
                            Text("[\(entry.timestamp.formatted(date: .omitted, time: .standard))] \(entry.message)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(colorForLevel(entry.level))
                        }
                    }
                }
                .frame(height: 300)
            }

            Section {
                Button("Clear Logs", role: .destructive) {
                    logger.clear()
                }
            }
        }
        .navigationTitle("Meet Debug")
    }

    private func colorForLevel(_ level: DebugLogLevel) -> Color {
        switch level {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        case .debug: return .secondary
        }
    }

    private func testCrypto() {
        do {
            let original = "abc123xyz"
            let encrypted = try MeetingCrypto.encryptMeetingID(original)
            let decrypted = try MeetingCrypto.decryptMeetingID(encrypted)
            MeetingLogger.info("Crypto Test: Original=\(original), Encrypted=\(encrypted), Decrypted=\(decrypted)")
        } catch {
            MeetingLogger.error("Crypto Test Failed: \(error.localizedDescription)")
        }
    }
}
