import SwiftUI

struct DeveloperCrashReportView: View {
    @ObservedObject var crashService = CrashReportService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var selectedAppID: UUID?
    @State private var reports: [CrashReport] = []
    @State private var isRefreshing = false

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("All Apps").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Crash Events") {
                if reports.isEmpty && !isRefreshing {
                    EmptyStateView(icon: "bandage.fill", title: "All Stable", message: "No crash reports detected for the selected application.")
                } else {
                    ForEach(reports) { report in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(report.exceptionType).font(.subheadline.bold()).foregroundStyle(.red)
                                Spacer()
                                Text(report.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.system(size: 8)).foregroundStyle(.secondary)
                            }

                            Text(report.reason).font(.system(size: 11)).lineLimit(2)

                            HStack {
                                Label(report.version, systemImage: "shippingbox").font(.system(size: 8, weight: .bold))
                                Spacer()
                                if report.isSymbolicated {
                                    Label("Symbolicated", systemImage: "checkmark.circle.fill").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Crash Reports")
        .onAppear { refreshReports() }
        .onChange(of: selectedAppID) { _ in refreshReports() }
    }

    private func refreshReports() {
        isRefreshing = true
        Task {
            let fetched = try? await crashService.fetchReports(appID: selectedAppID)
            await MainActor.run {
                self.reports = fetched ?? []
                self.isRefreshing = false
            }
        }
    }
}
