import SwiftUI
import UIKit

struct SecuritySessionManagerView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var activeSessions: [SecuritySession] = []

    var body: some View {
        List {
            Section {
                if let current = activeSessions.first(where: { $0.isCurrent }) {
                    SessionRow(session: current)
                }
            } header: {
                Text("Current Session")
            }

            Section {
                ForEach(activeSessions.filter { !$0.isCurrent }) { session in
                    SessionRow(session: session)
                        .swipeActions {
                            Button(role: .destructive) {
                                activeSessions.removeAll { $0.id == session.id }
                            } label: {
                                Label("Revoke", systemImage: "xmark.circle")
                            }
                        }
                }
            } header: {
                Text("Other Active Sessions")
            }

            Section {
                Button(role: .destructive) {
                    activeSessions.removeAll { !$0.isCurrent }
                } label: {
                    Text("Logout All Other Sessions")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Session Manager")
        .onAppear {
            loadSessions()
        }
    }

    private func loadSessions() {
        let grouped = Dictionary(grouping: authService.logs.filter { $0.type == .login }) { Calendar.current.startOfDay(for: $0.timestamp) }
        var sessions = grouped.keys.sorted(by: >).map { day in
            SecuritySession(id: UUID(), deviceName: UIDevice.current.name, location: "Current Device", lastActive: day, isCurrent: day == grouped.keys.max())
        }
        if sessions.isEmpty {
            sessions = [SecuritySession(id: UUID(), deviceName: UIDevice.current.name, location: "Current Device", lastActive: Date(), isCurrent: true)]
        }
        activeSessions = sessions
    }
}

struct SecuritySession: Identifiable {
    let id: UUID
    let deviceName: String
    let location: String
    let lastActive: Date
    let isCurrent: Bool
}

struct SessionRow: View {
    let session: SecuritySession

    var body: some View {
        HStack {
            Image(systemName: session.isCurrent ? "iphone.badge.play" : "iphone")
                .font(.title2)
                .foregroundStyle(session.isCurrent ? Color.blue : Color.secondary)
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
