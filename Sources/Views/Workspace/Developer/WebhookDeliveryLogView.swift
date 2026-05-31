import SwiftUI

struct WebhookDeliveryLogView: View {
    let endpointID: UUID
    @ObservedObject var webhookService = WebhookService.shared
    @State private var deliveries: [WebhookDelivery] = []
    @State private var isRefreshing = false

    var body: some View {
        List {
            Section("Transmission History") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "list.bullet.indent").foregroundStyle(.secondary)
                        Text("Delivery Status").font(.subheadline.bold())
                    }
                    Text("Detailed audit trail of event payloads sent to your registered endpoint in the last 24 hours.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Recent Events") {
                if deliveries.isEmpty && !isRefreshing {
                    EmptyStateView(icon: "bolt.horizontal", title: "No History", message: "Transmission logs will appear here as events are triggered for this endpoint.")
                } else {
                    ForEach(deliveries) { delivery in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(delivery.eventType.rawValue.uppercased())
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(.secondary)

                                Spacer()

                                statusBadge(delivery.statusCode)
                            }

                            HStack {
                                Text(delivery.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10, design: .monospaced))
                                Spacer()
                                Text("\(Int(delivery.duration * 1000))ms")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Delivery Log")
        .refreshable { refreshLog() }
        .onAppear { refreshLog() }
    }

    private func statusBadge(_ code: Int) -> some View {
        Text("\(code)")
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(code < 300 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .foregroundStyle(code < 300 ? .green : .red)
            .clipShape(Capsule())
    }

    private func refreshLog() {
        isRefreshing = true
        Task {
            let log = try? await webhookService.fetchDeliveryLog(endpointID: endpointID)
            await MainActor.run {
                deliveries = log ?? []
                isRefreshing = false
            }
        }
    }
}
