import SwiftUI

struct AnalyticsDashboardView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var analyticsService = AnalyticsService.shared
    @State private var timeRange = 0 // 7 days
    @State private var selectedAppId: UUID?

    var selectedApp: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Picker("App", selection: $selectedAppId) {
                        Text("All Apps").tag(UUID?.none)
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                    Spacer()
                    Picker("Range", selection: $timeRange) {
                        Text("7D").tag(0)
                        Text("30D").tag(1)
                        Text("90D").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }

                overviewStrip
                installTrendChart
                apiUsageSection
                marketplaceFunnel
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Analytics")
    }

    private var overviewStrip: some View {
        HStack {
            let totalInstalls = selectedApp?.installCount ?? appService.apps.reduce(0) { $0 + $1.installCount }
            let totalRevenue = selectedApp?.revenue ?? appService.apps.reduce(0) { $0 + $1.revenue }

            statItem(label: "Installs", value: "\(totalInstalls)", trend: "")
            statItem(label: "Active Users", value: "0", trend: "")
            statItem(label: "Revenue", value: "$\(String(format: "%.2f", totalRevenue))", trend: "")
            statItem(label: "Crashes", value: "0.0%", trend: "")
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(label: String, value: String, trend: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
            if !trend.isEmpty {
                Text(trend).font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var installTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Install Trend").font(.headline)

            VStack(alignment: .center) {
                Text("No data available").font(.caption).foregroundStyle(.secondary)
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var apiUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API Usage & Latency").font(.headline)

            VStack(spacing: 0) {
                Text("No API calls recorded for the selected period.").font(.caption).foregroundStyle(.secondary).padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var marketplaceFunnel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Marketplace Funnel").font(.headline)

            VStack(spacing: 12) {
                let installs = selectedApp?.installCount ?? appService.apps.reduce(0) { $0 + $1.installCount }
                funnelStep(label: "Impressions", value: "0", color: .blue)
                funnelStep(label: "Page Views", value: "0", color: .blue.opacity(0.8))
                funnelStep(label: "Installs", value: "\(installs)", color: .blue.opacity(0.6))
            }
        }
    }

    private func funnelStep(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label).font(.caption).bold()
            Spacer()
            Text(value).font(.caption.bold())
        }
        .padding()
        .background(color.opacity(0.1))
        .overlay(Rectangle().stroke(color, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
