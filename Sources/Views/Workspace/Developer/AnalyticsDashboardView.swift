import SwiftUI

struct AnalyticsDashboardView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var analyticsService = AnalyticsService.shared
    @ObservedObject var logService = DeveloperLogService.shared

    @State private var selectedAppID: UUID?
    @State private var timeRange: TimeRange = .day
    @State private var apiUsageCount = 0
    @State private var errorSummary: [String: Int] = [:]
    @State private var historicalUsage: [Double] = []

    enum TimeRange: String, CaseIterable {
        case hour = "1h"
        case day = "24h"
        case week = "7d"
        case month = "30d"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                filterBar

                VStack(alignment: .leading, spacing: 20) {
                    metricGrid

                    SectionHeader(title: "Usage Patterns", subtitle: "API requests and performance metrics over time.", icon: "chart.line.uptrend.xyaxis")
                    usageChart

                    SectionHeader(title: "Top Error Drivers", subtitle: "Aggregated critical failures across the fleet.", icon: "exclamationmark.triangle.fill")
                    errorSummaryList
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Analytics")
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
            refreshData()
        }
        .onChange(of: selectedAppID) { _ in refreshData() }
        .onChange(of: timeRange) { _ in refreshData() }
    }

    private var filterBar: some View {
        HStack(spacing: 12) {
            Picker("App", selection: $selectedAppID) {
                Text("All Apps").tag(Optional<UUID>.none)
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .padding(4)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            Picker("Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(label: "API Usage", value: "\(apiUsageCount)", icon: "arrow.up.right.circle", color: .blue)
            metricCard(label: "Error Rate", value: String(format: "%.2f%%", computeErrorRate()), icon: "bolt.fill", color: .red)
            metricCard(label: "Active Users", value: "1.2k", icon: "person.2.fill", color: .green)
            metricCard(label: "Avg Latency", value: "84ms", icon: "timer", color: .orange)
        }
    }

    private func metricCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).font(.caption).foregroundStyle(color)
                Spacer()
                Text("+2.4%").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title3.bold())
                Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private var usageChart: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 8) {
                if historicalUsage.isEmpty {
                    Text("Insufficient data for chart").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(0..<historicalUsage.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(height: CGFloat(historicalUsage[index] * 100))
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 120)
            .padding()
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var errorSummaryList: some View {
        VStack(spacing: 1) {
            if errorSummary.isEmpty {
                Text("No critical errors recorded in this time range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(errorSummary.sorted(by: { $0.value > $1.value }), id: \.key) { error, count in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(error).font(.subheadline.bold()).lineLimit(1)
                            Text("Fleet-wide impact").font(.system(size: 8)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(count)").font(.system(size: 12, weight: .black))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.red.opacity(0.1), in: Capsule())
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func computeErrorRate() -> Double {
        let total = Double(apiUsageCount)
        guard total > 0 else { return 0 }
        let errors = Double(errorSummary.values.reduce(0, +))
        return (errors / total) * 100
    }

    private func refreshData() {
        let fromDate: Date
        switch timeRange {
        case .hour: fromDate = Date().addingTimeInterval(-3600)
        case .day: fromDate = Date().addingTimeInterval(-86400)
        case .week: fromDate = Date().addingTimeInterval(-604800)
        case .month: fromDate = Date().addingTimeInterval(-2592000)
        }

        Task {
            let usage = try? await analyticsService.fetchAPIUsage(appID: selectedAppID, from: fromDate, to: Date())
            let errors = try? await analyticsService.fetchErrorSummary(appID: selectedAppID, from: fromDate, to: Date())

            // Derive historical usage from real log distribution
            var buckets = Array(repeating: 0.0, count: 12)
            if let logs = usage, !logs.isEmpty {
                let interval = Date().timeIntervalSince(fromDate) / 12
                for log in logs {
                    let bucketIndex = Int(log.timestamp.timeIntervalSince(fromDate) / interval)
                    if bucketIndex >= 0 && bucketIndex < 12 {
                        buckets[bucketIndex] += 1.0
                    }
                }
                let maxVal = buckets.max() ?? 1.0
                buckets = buckets.map { $0 / maxVal }
            }

            await MainActor.run {
                self.apiUsageCount = usage?.count ?? 0
                self.errorSummary = errors ?? [:]
                self.historicalUsage = buckets
            }
        }
    }
}
