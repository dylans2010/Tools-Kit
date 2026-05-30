import SwiftUI

struct DeveloperPerformanceMonitorView: View {
    @ObservedObject var performanceService = PerformanceService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var filteredMetrics: [PerformanceMetric] {
        performanceService.metrics.filter { selectedAppID == nil || $0.appID == selectedAppID }
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

            Section("Real-time Metrics") {
                if filteredMetrics.isEmpty {
                    EmptyStateView(icon: "gauge.with.needle", title: "No Performance Data", message: "Connect your application to start monitoring execution performance.")
                } else {
                    ForEach(filteredMetrics) { metric in
                        HStack {
                            Text(metric.name).font(.subheadline.bold())
                            Spacer()
                            Text("\(String(format: "%.2f", metric.value)) \(metric.unit)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Performance Monitor")
    }
}
