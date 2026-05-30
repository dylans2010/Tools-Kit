import SwiftUI

struct DeveloperCrashReportView: View {
    @ObservedObject var crashService = CrashReportService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var filteredCrashes: [CrashLog] {
        crashService.crashLogs.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("All Projects").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Crash Reports") {
                if filteredCrashes.isEmpty {
                    EmptyStateView(icon: "heart.text.square", title: "No Crashes", message: "No crash reports detected for the selected period.")
                } else {
                    ForEach(filteredCrashes) { log in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(log.version).font(.caption.bold()).foregroundStyle(.secondary)
                                Spacer()
                                Text(log.timestamp.formatted()).font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                            Text(log.deviceModel).font(.subheadline.bold())
                            Text(log.stackTrace.prefix(100) + "...").font(.system(size: 10, design: .monospaced)).foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Crash Reporting")
    }
}
