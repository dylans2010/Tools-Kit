import SwiftUI

struct WebhookTestView: View {
    let endpointID: UUID
    @ObservedObject var webhookService = WebhookService.shared
    @State private var isTesting = false
    @State private var result: (Int, String)?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "bolt.horizontal.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Transmission Test")
                        .font(.title3.bold())

                    Text("Send a signed test payload to verify your endpoint is correctly receiving and processing events.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 24)

                if let (code, response) = result {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Response Code").font(.system(size: 10, weight: .bold)).textCase(.uppercase).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(code)")
                                .font(.headline.monospaced())
                                .foregroundStyle(code < 300 ? .green : .red)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Response Body").font(.system(size: 10, weight: .bold)).textCase(.uppercase).foregroundStyle(.secondary)
                            Text(response.isEmpty ? "(Empty Response)" : response)
                                .font(.system(size: 11, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.primary.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                }

                Spacer()

                Button {
                    test()
                } label: {
                    if isTesting {
                        ProgressView().tint(.white).frame(maxWidth: .infinity)
                    } else {
                        Text("Trigger Test Delivery")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isTesting)
            }
            .padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
