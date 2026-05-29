import SwiftUI

struct AnalyticsDashboardView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var timeRange = 0 // 7 days
    @State private var selectedAppId: UUID?

    var selectedApp: DeveloperApp? {
        store.apps.first { $0.id == selectedAppId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Picker("App", selection: $selectedAppId) {
                        Text("All Apps").tag(UUID?.none)
                        ForEach(store.apps) { app in
                            Text(app.name).tag(UUID?.some(app.id))
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
                geographicDistribution
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
            let totalInstalls = selectedApp?.installCount ?? store.apps.reduce(0) { $0 + $1.installCount }
            let totalRevenue = selectedApp?.revenue ?? store.apps.reduce(0) { $0 + $1.revenue }

            statItem(label: "Installs", value: "\(totalInstalls)", trend: "+12%")
            statItem(label: "Active Users", value: "\(Int(Double(totalInstalls) * 0.6))", trend: "+5%")
            statItem(label: "Revenue", value: "$\(String(format: "%.0f", totalRevenue))", trend: "+18%")
            statItem(label: "Crashes", value: "0.2%", trend: "-0.1%")
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(label: String, value: String, trend: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.system(size: 8)).foregroundStyle(.secondary)
            Text(trend).font(.system(size: 8, weight: .bold))
                .foregroundStyle(trend.contains("+") ? .green : .red)
        }
        .frame(maxWidth: .infinity)
    }

    private var installTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Install Trend").font(.headline)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<14) { i in
                        let height = Double.random(in: 20...150)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.6))
                            .frame(height: height)
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)

                Divider()
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var geographicDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Geographic Distribution").font(.headline)

            VStack(spacing: 8) {
                geoRow(country: "United States", value: "45%", progress: 0.45)
                geoRow(country: "United Kingdom", value: "12%", progress: 0.12)
                geoRow(country: "Germany", value: "8%", progress: 0.08)
                geoRow(country: "Japan", value: "5%", progress: 0.05)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func geoRow(country: String, value: String, progress: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(country).font(.caption)
                Spacer()
                Text(value).font(.caption.bold())
            }
            ProgressView(value: progress)
                .tint(.blue)
        }
    }

    private var apiUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("API Usage & Latency").font(.headline)

            VStack(spacing: 0) {
                apiRow(endpoint: "/v1/sync", calls: "12.4k", latency: "120ms", error: "0.1%")
                Divider()
                apiRow(endpoint: "/v1/auth", calls: "2.1k", latency: "240ms", error: "0.5%")
                Divider()
                apiRow(endpoint: "/v1/search", calls: "8.5k", latency: "450ms", error: "1.2%")
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func apiRow(endpoint: String, calls: String, latency: String, error: String) -> some View {
        HStack {
            Text(endpoint).font(.caption.monospaced()).bold()
            Spacer()
            VStack(alignment: .trailing) {
                Text(calls).font(.caption)
                HStack(spacing: 8) {
                    Text(latency).foregroundStyle(.secondary)
                    Text(error).foregroundStyle(.red)
                }
                .font(.system(size: 8))
            }
        }
        .padding()
    }

    private var marketplaceFunnel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Marketplace Funnel").font(.headline)

            VStack(spacing: 12) {
                let impressions = (selectedApp?.installCount ?? 100) * 40
                let pageViews = (selectedApp?.installCount ?? 100) * 10
                let installs = selectedApp?.installCount ?? store.apps.reduce(0) { $0 + $1.installCount }

                funnelStep(label: "Impressions", value: "\(impressions)", color: .blue)
                funnelStep(label: "Page Views", value: "\(pageViews)", color: .blue.opacity(0.8))
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
