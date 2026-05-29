import SwiftUI

struct WebhookDeliveryLogView: View {
    let endpointID: UUID
    @ObservedObject var webhookService = WebhookService.shared
    @State private var deliveries: [WebhookDelivery] = []

    var body: some View {
        List {
            Section("Recent Deliveries") {
                if deliveries.isEmpty {
                    Text("No delivery history for this endpoint.").foregroundStyle(.secondary)
                } else {
                    ForEach(deliveries) { delivery in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(delivery.eventType.rawValue).font(.subheadline.bold())
                                Text(delivery.timestamp.formatted()).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            statusBadge(delivery.statusCode)
                        }
                    }
                }
            }
        }
        .navigationTitle("Delivery Log")
        .onAppear {
            Task {
                let log = try? await webhookService.fetchDeliveryLog(endpointID: endpointID)
                await MainActor.run {
                    deliveries = log ?? []
                }
            }
        }
    }

    private func statusBadge(_ code: Int) -> some View {
        Text("\(code)")
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(code < 300 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .foregroundStyle(code < 300 ? .green : .red)
            .clipShape(Capsule())
    }
}
