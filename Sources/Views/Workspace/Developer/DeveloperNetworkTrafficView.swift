import SwiftUI

struct DeveloperNetworkTrafficView: View {
    @ObservedObject var networkService = NetworkMonitorService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var filteredRequests: [NetworkRequest] {
        networkService.requests.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        VStack(spacing: 0) {
            trafficHeader

            List {
                Section("Live Traffic Stream") {
                    if filteredRequests.isEmpty {
                        EmptyStateView(icon: "wifi.router", title: "No Network Activity", message: "Start your application and execute API requests to begin monitoring real-time network telemetry.")
                            .padding(.vertical, 40)
                    } else {
                        ForEach(filteredRequests) { request in
                            networkRequestRow(request)
                        }
                    }
                }
            }
        }
        .navigationTitle("Network Traffic")
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private var trafficHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Filter by Application", selection: $selectedAppID) {
                Text("All Project Traffic").tag(Optional<UUID>.none)
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .padding(4)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 32) {
                trafficMetric(label: "Throughput", value: "842 KB/s", color: .blue)
                trafficMetric(label: "Error Rate", value: "0.2%", color: .red)
                trafficMetric(label: "Avg Latency", value: "142ms", color: .orange)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func trafficMetric(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
        }
    }

    private func networkRequestRow(_ request: NetworkRequest) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .center, spacing: 2) {
                Text(request.method).font(.system(size: 8, weight: .black)).foregroundStyle(.secondary)
                Text("\(request.statusCode)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(request.statusCode < 300 ? .green : (request.statusCode < 400 ? .orange : .red))
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(request.url).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                Text(request.timestamp.formatted(date: .omitted, time: .standard)).font(.system(size: 9)).foregroundStyle(.tertiary)
            }

            Spacer()

            Text("\(Int(request.duration * 1000))ms")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
