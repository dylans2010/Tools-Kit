import SwiftUI

struct DeveloperAccountActivityView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @State private var activities: [AccountActivityEvent] = [
        AccountActivityEvent(eventType: "Console Login", deviceName: "MacBook Pro 16", ipAddress: "192.168.1.42", timestamp: Date().addingTimeInterval(-3600)),
        AccountActivityEvent(eventType: "API Key Created", deviceName: "CLI / Terminal", ipAddress: "192.168.1.42", timestamp: Date().addingTimeInterval(-7200)),
        AccountActivityEvent(eventType: "Password Change", deviceName: "Web Browser", ipAddress: "104.22.4.12", timestamp: Date().addingTimeInterval(-86400))
    ]

    var body: some View {
        List {
            Section("Identity & Security Audit") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.text.badge.checkmark").foregroundStyle(.green)
                        Text("Session Integrity Verified").font(.subheadline.bold())
                    }
                    Text("We monitor account activity to detect unauthorized access and ensure your developer credentials remain secure.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Recent Events") {
                if activities.isEmpty {
                    EmptyStateView(icon: "person.text.rectangle", title: "No Activity", message: "No security events recorded for your account in the last 30 days.")
                } else {
                    ForEach(activities) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.eventType).font(.subheadline.bold())
                                Spacer()
                                Text(event.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            HStack {
                                Text(event.deviceName).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                                Circle().fill(.secondary).frame(width: 2, height: 2)
                                Text(event.ipAddress).font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Activity Audit")
    }
}

