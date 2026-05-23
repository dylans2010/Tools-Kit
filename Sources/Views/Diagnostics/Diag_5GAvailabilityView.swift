import SwiftUI

struct Diag_5GAvailabilityView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "5.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text("5G Standalone Supported")
                        .font(.headline)

                    Text("Your device and carrier support 5G Standalone (SA) and Non-Standalone (NSA) modes.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Technology Details") {
                LabeledContent("5G NSA", value: "Available")
                LabeledContent("5G SA", value: "Available")
                LabeledContent("mmWave Support", value: "Detected (US models)")
                LabeledContent("Sub-6GHz Support", value: "Available")
            }

            Section("Radio Resource Control") {
                LabeledContent("RRC State", value: "Connected")
                LabeledContent("Primary Band", value: "n78")
            }
        }
        .navigationTitle("5G Availability")
    }
}
