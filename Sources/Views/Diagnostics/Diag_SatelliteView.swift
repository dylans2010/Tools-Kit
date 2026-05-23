import SwiftUI

struct Diag_SatelliteView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var isSearching = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image(systemName: "satellite.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(service.supportsSatelliteConnectivity ? .blue : .gray)
                        .symbolEffect(.pulse, isActive: isSearching)

                    Text(service.supportsSatelliteConnectivity ? "Satellite Support Available" : "Satellite Not Supported")
                        .font(.headline)

                    Text("iPhone 14 and later models support Emergency SOS via Satellite and Find My via Satellite.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Connection Status") {
                LabeledContent("Hardware Support") {
                    Text(service.supportsSatelliteConnectivity ? "Detected" : "Missing")
                        .foregroundStyle(service.supportsSatelliteConnectivity ? .green : .red)
                }

                LabeledContent("Link Status") {
                    if service.isSatelliteActive {
                        Text("Active")
                            .foregroundStyle(.green)
                    } else {
                        Text("Inactive")
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Simulated Signal") {
                    if isSearching {
                        ProgressView()
                    } else {
                        Text(service.supportsSatelliteConnectivity ? "Strong" : "No Signal")
                    }
                }
            }

            Section {
                Button(action: {
                    withAnimation {
                        isSearching.toggle()
                    }
                }) {
                    Text(isSearching ? "Cancel Search" : "Search for Satellites")
                }
                .disabled(!service.supportsSatelliteConnectivity)
            }

            Section(footer: Text("Satellite connectivity requires a clear view of the sky and is not available in all regions.")) {
                EmptyView()
            }
        }
        .navigationTitle("Satellite Conn")
    }
}
