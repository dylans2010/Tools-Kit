import SwiftUI

struct Diag_PrivacyReportView: View {
    @State private var privacyEntries: [PrivacyEntry] = [
        PrivacyEntry(app: "Photos", category: "Photos Library", lastAccess: Date().addingTimeInterval(-3600), count: 42),
        PrivacyEntry(app: "Maps", category: "Location", lastAccess: Date().addingTimeInterval(-1800), count: 12),
        PrivacyEntry(app: "Contacts", category: "Contacts", lastAccess: Date().addingTimeInterval(-7200), count: 5),
        PrivacyEntry(app: "Microphone", category: "Audio", lastAccess: Date().addingTimeInterval(-600), count: 1)
    ]

    var body: some View {
        List {
            Section("Recent Access") {
                ForEach(privacyEntries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.app)
                                .font(.headline)
                            Text(entry.category)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(entry.count) times")
                                .font(.caption)
                            Text(entry.lastAccess, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section("System Audit") {
                LabeledContent("App Tracking Transparency", value: "Enabled")
                LabeledContent("Privacy Preserving Ad Measurement", value: "Active")
                LabeledContent("Local Network Scan", value: "Restricted")
            }
        }
        .navigationTitle("App Privacy Report")
    }
}

struct PrivacyEntry: Identifiable {
    let id = UUID()
    let app: String
    let category: String
    let lastAccess: Date
    let count: Int
}
