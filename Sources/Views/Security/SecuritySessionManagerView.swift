import SwiftUI

struct SecuritySessionManagerView: View {
    @StateObject private var store = SecurityDeviceSessionStore.shared

    private var currentSession: SecuritySession? {
        store.sessions.first(where: { $0.isCurrent })
    }

    private var otherSessions: [SecuritySession] {
        store.sessions.filter { !$0.isCurrent }.sorted(by: { $0.lastActive > $1.lastActive })
    }

    var body: some View {
        List {
            Section("Current Session") {
                if let currentSession {
                    SessionRow(session: currentSession)
                }
            }

            Section("Other Active Sessions") {
                if otherSessions.isEmpty {
                    Text("No other active sessions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(otherSessions) { session in
                        SessionRow(session: session)
                            .swipeActions {
                                Button(role: .destructive) {
                                    store.revokeSession(session)
                                } label: {
                                    Label("Revoke", systemImage: "xmark.circle")
                                }
                            }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    store.revokeAllOtherSessions()
                } label: {
                    Text("Logout All Other Sessions")
                        .frame(maxWidth: .infinity)
                }
                .disabled(otherSessions.isEmpty)
            }
        }
        .navigationTitle("Session Manager")
        .onAppear {
            store.refreshCurrentSessionActivity()
        }
    }
}

struct SessionRow: View {
    let session: SecuritySession

    var body: some View {
        HStack {
            Image(systemName: session.isCurrent ? "iphone.badge.play" : "iphone")
                .font(.title2)
                .foregroundStyle(session.isCurrent ? .blue : .secondary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.deviceName)
                    .font(.subheadline.bold())
                Text("\(session.location) • \(session.lastActive, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if session.isCurrent {
                Text("Current")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
