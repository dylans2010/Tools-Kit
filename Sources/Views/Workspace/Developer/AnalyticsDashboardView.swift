import SwiftUI

struct AnalyticsDashboardView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var analyticsService = AnalyticsService.shared
    @State private var selectedAppID: UUID?
    @State private var selectedTimeRange: TimeRange = .last7Days
    @State private var isLoading = false
    @State private var errorSummary: [String: Int] = [:]
    @State private var apiUsageCount: Int = 0

    enum TimeRange: String, CaseIterable {
        case last24Hours = "Last 24 Hours"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                filterHeader

                if isLoading {
                    ProgressView().padding(100)
                } else {
                    mainMetricsGrid
                    errorSummarySection
                    apiUsageSection
                }
            }
            .padding()
        }
        .navigationTitle("Analytics")
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear(perform: refreshData)
        .onChange(of: selectedAppID) { _ in refreshData() }
        .onChange(of: selectedTimeRange) { _ in refreshData() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { try? await analyticsService.exportMetrics(appID: selectedAppID, from: Date().addingTimeInterval(-7*24*3600), to: Date(), format: "json") }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private var filterHeader: some View {
        VStack(spacing: 12) {
            Picker("Project", selection: $selectedAppID) {
                Text("All Projects").tag(Optional<UUID>.none)
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            Picker("Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var mainMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(label: "Total Installs", value: "\(totalInstalls)", icon: "arrow.down.circle", color: .blue)
            metricCard(label: "API Requests", value: "\(apiUsageCount)", icon: "bolt.fill", color: .orange)
            metricCard(label: "Active Keys", value: "\(activeKeysCount)", icon: "key.fill", color: .green)
            metricCard(label: "Error Events", value: "\(errorCount)", icon: "exclamationmark.triangle.fill", color: .red)
        }
    }

    private var totalInstalls: Int {
        appService.apps.filter { selectedAppID == nil || $0.id == selectedAppID }.reduce(0) { $0 + $1.installCount }
    }

    private var activeKeysCount: Int {
        APIKeyService.shared.keys.filter { (selectedAppID == nil || $0.appID == selectedAppID) && !$0.isRevoked }.count
    }

    private var errorCount: Int {
        errorSummary.values.reduce(0, +)
    }

    private func metricCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Spacer()
            }
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var errorSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Top Errors", subtitle: nil, icon: nil)

            if errorSummary.isEmpty {
                EmptyStateView(icon: "checkmark.shield", title: "No Errors", message: "No errors reported for this period.")
            } else {
                VStack(spacing: 1) {
                    ForEach(errorSummary.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { error, count in
                        HStack {
                            Text(error).font(.caption).lineLimit(1)
                            Spacer()
                            Text("\(count)").font(.caption.bold()).foregroundStyle(.red)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var apiUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "API Usage", subtitle: nil, icon: nil)

            if apiUsageCount == 0 {
                EmptyStateView(icon: "bolt.slash", title: "No API Usage", message: "No API usage recorded.")
            } else {
                Text("Total of \(apiUsageCount) API calls recorded in the selected period.")
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func refreshData() {
        isLoading = true
        Task {
            let from = dateFromRange(selectedTimeRange)
            let to = Date()

            let usage = try? await analyticsService.fetchAPIUsage(appID: selectedAppID, from: from, to: to)
            let errors = try? await analyticsService.fetchErrorSummary(appID: selectedAppID, from: from, to: to)

            await MainActor.run {
                apiUsageCount = usage?.count ?? 0
                errorSummary = errors ?? [:]
                isLoading = false
            }
        }
    }

    private func dateFromRange(_ range: TimeRange) -> Date {
        switch range {
        case .last24Hours: return Date().addingTimeInterval(-24 * 3600)
        case .last7Days: return Date().addingTimeInterval(-7 * 24 * 3600)
        case .last30Days: return Date().addingTimeInterval(-30 * 24 * 3600)
        case .last90Days: return Date().addingTimeInterval(-90 * 24 * 3600)
        }
    }
}
