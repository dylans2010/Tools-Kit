import SwiftUI
import CoreLocation

struct Diag_GPSView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var isMonitoring = false

    var body: some View {
        Form {
            Section("Current Location") {
                if let location = service.lastLocation {
                    LabeledContent("Latitude") {
                        Text(String(format: "%.6f°", location.coordinate.latitude))
                            .monospacedDigit()
                    }
                    LabeledContent("Longitude") {
                        Text(String(format: "%.6f°", location.coordinate.longitude))
                            .monospacedDigit()
                    }
                    LabeledContent("Altitude") {
                        Text(String(format: "%.1f m", location.altitude))
                            .monospacedDigit()
                    }
                    LabeledContent("Speed") {
                        Text(String(format: "%.1f m/s", max(0, location.speed)))
                            .monospacedDigit()
                    }
                } else {
                    Text("Searching for GPS signal...")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }

            Section("Accuracy") {
                if let location = service.lastLocation {
                    LabeledContent("Horizontal") {
                        Text(String(format: "±%.1f m", location.horizontalAccuracy))
                            .monospacedDigit()
                    }
                    LabeledContent("Vertical") {
                        Text(String(format: "±%.1f m", location.verticalAccuracy))
                            .monospacedDigit()
                    }
                }
            }

            Section("Status") {
                if let error = service.locationError {
                    Text("Error: \(error.localizedDescription)")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button {
                    if isMonitoring {
                        service.stopLocationUpdates()
                    } else {
                        service.requestLocationPermissions()
                        service.startLocationUpdates()
                    }
                    isMonitoring.toggle()
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "location.circle.fill")
                        Text(isMonitoring ? "Stop Updates" : "Start Updates")
                    }
                }
            }
        }
        .navigationTitle("GPS Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            service.stopLocationUpdates()
        }
    }
}
