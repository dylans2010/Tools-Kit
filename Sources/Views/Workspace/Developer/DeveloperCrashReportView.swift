import SwiftUI

struct DeveloperCrashReportView: View {
    @ObservedObject var crashService = CrashReportService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var selectedAppID: UUID?
    @State private var reports: [CrashLog] = []
    @State private var isRefreshing = false

    private var apps: [DeveloperApp] { appService.apps }

    var body: some View {
        List {
            appPickerSection
            crashEventsSection
        }
        .navigationTitle("Crash Reports")
        .onAppear { refreshReports() }
        .onChange(of: selectedAppID) { _ in refreshReports() }
    }

    private var appPickerSection: some View {
        Section {
            Picker("App", selection: $selectedAppID) {
                Text("All Apps").tag(Optional<UUID>.none)
                ForEach(apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
        }
    }

    @ViewBuilder
    private var crashEventsSection: some View {
        Section("Crash Events") {
            if reports.isEmpty && !isRefreshing {
                crashReportsEmptyState
            } else {
                crashReportRows
            }
        }
    }

    private var crashReportsEmptyState: some View {
        EmptyStateView(
            icon: "bandage.fill",
            title: "All Stable",
            message: "No crash reports detected for the selected application."
        )
    }

    private var crashReportRows: some View {
        ForEach(reports) { report in
            crashReportRow(report)
        }
    }

    private func crashReportRow(_ report: CrashLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            crashReportHeader(report)
            crashReportReason(report)
            crashReportFooter(report)
        }
        .padding(.vertical, 4)
    }

    private func crashReportHeader(_ report: CrashLog) -> some View {
        HStack {
            Text(report.exceptionType)
                .font(.subheadline.bold())
                .foregroundStyle(.red)
            Spacer()
            Text(report.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
    }

    private func crashReportReason(_ report: CrashLog) -> some View {
        Text(report.reason)
            .font(.system(size: 11))
            .lineLimit(2)
    }

    @ViewBuilder
    private func crashReportFooter(_ report: CrashLog) -> some View {
        HStack {
            Label(report.version, systemImage: "shippingbox")
                .font(.system(size: 8, weight: .bold))
            Spacer()
            if report.isSymbolicated {
                Label("Symbolicated", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.green)
            }
        }
    }

    private func refreshReports() {
        isRefreshing = true
        let appID: UUID? = selectedAppID
        Task {
            let fetched = try? await crashService.fetchReports(appID: appID)
            await MainActor.run {
                self.reports = fetched ?? []
                self.isRefreshing = false
            }
        }
    }
}
