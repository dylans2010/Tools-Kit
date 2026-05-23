import SwiftUI

struct Diag_SatelliteView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        Form {
            Section("Hardware Support") {
                VStack(spacing: 20) {
                    Image(systemName: service.isSatelliteSupported ? "satellite.fill" : "satellite")
                        .font(.system(size: 60))
                        .foregroundStyle(service.isSatelliteSupported ? .green : .secondary)
                        .padding()

                    Text(service.isSatelliteSupported ? "Satellite Connectivity Supported" : "Satellite Connectivity Not Supported")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("Satellite connectivity requires iPhone 14 or later and appropriate environmental conditions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Device Metrics") {
                LabeledContent("Model ID", value: service.deviceModelIdentifier)
                LabeledContent("Region Code") {
                    Text(Locale.current.region?.identifier ?? "Unknown")
                }
            }

            Section {
                Text("Emergency SOS via satellite is available on iPhone 14 and later models. This diagnostic verifies hardware compatibility based on device identifiers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Satellite Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
