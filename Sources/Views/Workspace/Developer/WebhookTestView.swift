import SwiftUI

struct WebhookTestView: View {
    let endpointID: UUID
    @ObservedObject var webhookService = WebhookService.shared
    @State private var isTesting = false
    @State private var result: (Int, String)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("Test Webhook")
                .font(.title2.bold())

            Text("Send a test payload to verify your endpoint is correctly receiving and processing events.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let (code, response) = result {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Response Code: \(code)")
                        .font(.headline)
                        .foregroundStyle(code < 300 ? .green : .red)
                    Text("Body:")
                        .font(.caption.bold())
                    ScrollView {
                        Text(response)
                            .font(.system(size: 10, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .frame(maxHeight: 200)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                test()
            } label: {
                if isTesting {
                    ProgressView().tint(.white)
                } else {
                    Text("Send Test Payload")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTesting)
        }
        .padding()
        .navigationTitle("Test Delivery")
    }

    private func test() {
        isTesting = true
        Task {
            let res = try? await webhookService.testDelivery(endpointID: endpointID)
            await MainActor.run {
                result = res
                isTesting = false
            }
        }
    }
}
