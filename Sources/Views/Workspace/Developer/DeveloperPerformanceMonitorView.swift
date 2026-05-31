import SwiftUI

struct DeveloperPerformanceMonitorView: View {
    @ObservedObject var performanceService = PerformanceService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var selectedAppID: UUID?
    @State private var metrics: PerformanceReport?
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appSelector

                if let report = metrics {
                    VStack(alignment: .leading, spacing: 24) {
                        SectionHeader(title: "Execution Health", subtitle: "Main thread latency and execution speed audit.", icon: "bolt.heart.fill")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            metricCard(label: "P99 Latency", value: "\(report.p99Latency)ms", color: report.p99Latency < 100 ? .green : .orange)
                            metricCard(label: "FPS (Avg)", value: "\(Int(report.avgFPS))", color: report.avgFPS > 55 ? .green : .red)
                            metricCard(label: "Cold Start", value: "\(report.coldStartTime)ms", color: .blue)
                            metricCard(label: "Memory Peak", value: "\(report.peakMemoryMB)MB", color: .purple)
                        }

                        SectionHeader(title: "Thread Utilization", subtitle: "Worker thread saturation and context switch overhead.", icon: "cpu")
                        threadSaturationList(report)
                    }
                    .padding()
                } else if selectedAppID != nil {
                    ProgressView().padding(.top, 40)
                } else {
                    EmptyStateView(icon: "gauge.with.needle", title: "Select an App", message: "Choose an application to view real-time performance telemetry.")
                        .padding(.top, 40)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Performance")
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
            refreshMetrics()
        }
        .onChange(of: selectedAppID) { _ in refreshMetrics() }
    }

    private var appSelector: some View {
        HStack {
            Picker("App", selection: $selectedAppID) {
                Text("Select App").tag(Optional<UUID>.none)
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            Spacer()
            Button { refreshMetrics() } label: { Image(systemName: "arrow.clockwise") }.disabled(isRefreshing)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func metricCard(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.title2.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    private func threadSaturationList(_ report: PerformanceReport) -> some View {
        VStack(spacing: 12) {
            ForEach(report.threadMetrics) { thread in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(thread.name).font(.subheadline.bold())
                        Text("Active for \(thread.activeTime)ms").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(thread.utilization * 100))%").font(.system(size: 11, weight: .black))
                        ProgressView(value: thread.utilization).tint(thread.utilization > 0.8 ? .red : .blue).frame(width: 60)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func refreshMetrics() {
        guard let appID = selectedAppID else { return }
        isRefreshing = true
        Task {
            let report = try? await performanceService.getLatestReport(appID: appID)
            await MainActor.run {
                self.metrics = report
                self.isRefreshing = false
            }
        }
    }
}
