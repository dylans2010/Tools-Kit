import SwiftUI

struct SecurityActivityLogView: View {
    @ObservedObject private var authService = AuthService.shared

    var body: some View {
        List {
            if authService.logs.isEmpty {
                Text("No activity logs available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(authService.logs) { log in
                    HStack(spacing: 12) {
                        Image(systemName: iconFor(log.type))
                            .foregroundStyle(colorFor(log.type))
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(log.message)
                                .font(.subheadline.bold())
                            Text(log.timestamp.formatted())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Activity Log")
        .toolbar {
            Button {
                // Export logic - using real logs
                let logText = authService.logs.map { "[\($0.timestamp)] \($0.type.rawValue.uppercased()): \($0.message)" }.joined(separator: "\n")
                UIPasteboard.general.string = logText
            } label: {
                Label("Copy Logs", systemImage: "doc.on.doc")
            }
        }
    }

    private func iconFor(_ type: SecurityLogEvent.LogType) -> String {
        switch type {
        case .login: return "person.badge.shield.checkmark.fill"
        case .failedLogin: return "person.badge.shield.exclamationmark.fill"
        case .settingsChange: return "gearshape.fill"
        case .vaultAccess: return "key.fill"
        case .threat: return "exclamationmark.shield.fill"
        }
    }

    private func colorFor(_ type: SecurityLogEvent.LogType) -> Color {
        switch type {
        case .login: return .green
        case .failedLogin: return .red
        case .settingsChange: return .blue
        case .vaultAccess: return .orange
        case .threat: return .purple
        }
    }
}
