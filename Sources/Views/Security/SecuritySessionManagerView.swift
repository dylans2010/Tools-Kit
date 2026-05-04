import SwiftUI

struct SecuritySessionManagerView: View {
    @State private var activeSessions: [SecuritySession] = [
        SecuritySession(id: UUID(), deviceName: "iPhone 15 Pro", location: "San Francisco, CA", lastActive: Date(), isCurrent: true),
        SecuritySession(id: UUID(), deviceName: "iPad Pro", location: "Oakland, CA", lastActive: Date().addingTimeInterval(-3600), isCurrent: false)
    ]

    var body: some View {
        List {
            Section("Current Session") {
                if let current = activeSessions.first(where: { $0.isCurrent }) {
                    SessionRow(session: current)
                }
            }

            Section("Other Active Sessions") {
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
