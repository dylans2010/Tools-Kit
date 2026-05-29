import SwiftUI

struct DeveloperAccountActivityView: View {
    @State private var activities: [AccountActivityEvent] = []

    var body: some View {
        List {
            Section("Recent Login & Security Activity") {
                if activities.isEmpty {
                    Text("No recent account activity recorded.").foregroundStyle(.secondary)
                } else {
                    ForEach(activities) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.eventType).font(.subheadline.bold())
                                Spacer()
                                Text(event.timestamp.formatted()).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Text("\(event.deviceName) • \(event.ipAddress)").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Account Activity")
        .onAppear {
            // Load activities from profile service
        }
    }
}
