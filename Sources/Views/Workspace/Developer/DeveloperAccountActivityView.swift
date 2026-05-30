import SwiftUI

struct DeveloperAccountActivityView: View {
    @ObservedObject var profileService = DeveloperProfileService.shared
    @State private var activities: [DeveloperActivityEvent] = []

    var body: some View {
        List {
            Section("Recent Login & Security Activity") {
                if profileService.profile.activities.isEmpty {
                    Text("No recent account activity recorded.").foregroundStyle(.secondary)
                } else {
                    ForEach(profileService.profile.activities) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.eventType.rawValue).font(.subheadline.bold())
                                Spacer()
                                Text(event.timestamp.formatted()).font(.caption2).foregroundStyle(.tertiary)
                            }
                            Text(event.description).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Account Activity")
    }
}
