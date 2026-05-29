import SwiftUI

struct DeveloperIntegrationGalleryView: View {
    let integrations = [
        ("GitHub", "Connect your repositories for automated builds."),
        ("Slack", "Get notifications for app events in your channels."),
        ("App Store Connect", "Sync app metadata and manage submissions."),
        ("Google Play Console", "Manage Android app listings and releases."),
        ("Jira", "Link crash reports to your development tickets.")
    ]

    var body: some View {
        List {
            Section("Available Integrations") {
                ForEach(integrations, id: \.0) { integration in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(Image(systemName: "puzzlepiece.fill").foregroundStyle(.secondary))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(integration.0).font(.subheadline.bold())
                            Text(integration.1).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Connect") {}
                            .font(.caption.bold())
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Integrations")
    }
}
