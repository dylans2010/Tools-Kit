import SwiftUI
import CoreLocation

struct Diag_GPSSignalView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        List {
            Section("Coordinate Data") {
                LabeledContent("Latitude") {
                    Text(service.lastLocation?.coordinate.latitude.description ?? "N/A")
                        .monospacedDigit()
                }
                LabeledContent("Longitude") {
                    Text(service.lastLocation?.coordinate.longitude.description ?? "N/A")
                        .monospacedDigit()
                }
                LabeledContent("Horizontal Accuracy") {
                    if let accuracy = service.lastLocation?.horizontalAccuracy {
                        Text("\(accuracy, specifier: "%.2f") m")
                    } else {
                        Text("N/A")
                    }
                }
            }

            Section("Altitude & Speed") {
                LabeledContent("Altitude") {
                    if let altitude = service.lastLocation?.altitude {
                        Text("\(altitude, specifier: "%.2f") m")
                    } else {
                        Text("N/A")
                    }
                }
                LabeledContent("Vertical Accuracy") {
                    if let accuracy = service.lastLocation?.verticalAccuracy {
                        Text("\(accuracy, specifier: "%.2f") m")
                    } else {
                        Text("N/A")
                    }
                }
                LabeledContent("Speed") {
                    if let speed = service.lastLocation?.speed {
                        Text("\(speed, specifier: "%.2f") m/s")
                    } else {
                        Text("N/A")
                    }
                }
            }

            Section("Status") {
                LabeledContent("Services Enabled") {
                    Text(service.isLocationServicesEnabled ? "Yes" : "No")
                        .foregroundStyle(service.isLocationServicesEnabled ? .green : .red)
                }
                LabeledContent("Authorization") {
                    Text(authStatusString)
                }
            }

            Section {
                Button(action: {
                    service.requestLocationPermissions()
                    service.startLocationUpdates()
                }) {
                    Label("Start Updates", systemImage: "play.fill")
                }

                Button(role: .destructive, action: {
                    service.stopLocationUpdates()
                }) {
                    Label("Stop Updates", systemImage: "stop.fill")
                }
            }
        }
        .navigationTitle("GPS Signal")
        .onAppear {
            service.startLocationUpdates()
        }
    }

    private var authStatusString: String {
        switch service.locationAuthorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
}
