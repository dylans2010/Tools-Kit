import SwiftUI
import CoreLocation

struct Diag_GPSLocationView: View {
    @StateObject private var locationManager = GPSLocationManager()

    var body: some View {
        Form {
            Section("Location Status") {
                LabeledContent("Authorization") {
                    Text(locationManager.authorizationStatus)
                        .foregroundStyle(locationManager.isAuthorized ? .green : .orange)
                }
                LabeledContent("Location Services") {
                    Text(CLLocationManager.locationServicesEnabled() ? "Enabled" : "Disabled")
                        .foregroundStyle(CLLocationManager.locationServicesEnabled() ? .green : .red)
                }
                LabeledContent("Accuracy Auth") {
                    Text(locationManager.accuracyAuthorization)
                }
            }

            if let location = locationManager.lastLocation {
                Section("Coordinates") {
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
                    LabeledContent("Floor") {
                        Text(location.floor.map { "\($0.level)" } ?? "N/A")
                    }
                }

                Section("Accuracy") {
                    LabeledContent("Horizontal") {
                        Text(String(format: "± %.1f m", location.horizontalAccuracy))
                            .monospacedDigit()
                            .foregroundStyle(accuracyColor(location.horizontalAccuracy))
                    }
                    LabeledContent("Vertical") {
                        Text(String(format: "± %.1f m", location.verticalAccuracy))
                            .monospacedDigit()
                            .foregroundStyle(accuracyColor(location.verticalAccuracy))
                    }
                    LabeledContent("Speed") {
                        Text(location.speed >= 0 ? String(format: "%.1f m/s", location.speed) : "N/A")
                            .monospacedDigit()
                    }
                    LabeledContent("Course") {
                        Text(location.course >= 0 ? String(format: "%.1f°", location.course) : "N/A")
                            .monospacedDigit()
                    }
                    LabeledContent("Timestamp") {
                        Text(location.timestamp, style: .time)
                    }
                }
            }

            Section("GPS Signal Quality") {
                HStack {
                    Image(systemName: locationManager.signalIcon)
                        .font(.title2)
                        .foregroundStyle(locationManager.signalColor)
                    VStack(alignment: .leading) {
                        Text(locationManager.signalQuality)
                            .font(.headline)
                        Text(locationManager.signalDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                Button {
                    locationManager.toggleUpdates()
                } label: {
                    HStack {
                        Image(systemName: locationManager.isUpdating ? "location.slash.fill" : "location.fill")
                        Text(locationManager.isUpdating ? "Stop Tracking" : "Start Tracking")
                    }
                }
                if !locationManager.isAuthorized {
                    Button("Request Permission") {
                        locationManager.requestPermission()
                    }
                }
            }
        }
        .navigationTitle("GPS Location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { locationManager.startUpdates() }
        .onDisappear { locationManager.stopUpdates() }
    }

    private func accuracyColor(_ accuracy: CLLocationAccuracy) -> Color {
        if accuracy < 0 { return .secondary }
        if accuracy <= 5 { return .green }
        if accuracy <= 20 { return .yellow }
        return .red
    }
}

final class GPSLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var lastLocation: CLLocation?
    @Published var isUpdating = false

    var authorizationStatus: String {
        switch manager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }

    var accuracyAuthorization: String {
        switch manager.accuracyAuthorization {
        case .fullAccuracy: return "Full Accuracy"
        case .reducedAccuracy: return "Reduced Accuracy"
        @unknown default: return "Unknown"
        }
    }

    var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }

    var signalIcon: String {
        guard let loc = lastLocation else { return "location.slash" }
        if loc.horizontalAccuracy <= 5 { return "location.fill" }
        if loc.horizontalAccuracy <= 20 { return "location" }
        return "location.slash"
    }

    var signalColor: Color {
        guard let loc = lastLocation else { return .secondary }
        if loc.horizontalAccuracy <= 5 { return .green }
        if loc.horizontalAccuracy <= 20 { return .yellow }
        return .red
    }

    var signalQuality: String {
        guard let loc = lastLocation else { return "No Signal" }
        if loc.horizontalAccuracy <= 5 { return "Excellent" }
        if loc.horizontalAccuracy <= 10 { return "Good" }
        if loc.horizontalAccuracy <= 20 { return "Fair" }
        return "Poor"
    }

    var signalDescription: String {
        guard let loc = lastLocation else { return "Waiting for GPS fix..." }
        return "Horizontal accuracy: \(String(format: "%.1f", loc.horizontalAccuracy))m"
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdates() {
        if isAuthorized {
            manager.startUpdatingLocation()
            isUpdating = true
        } else {
            requestPermission()
        }
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()
        isUpdating = false
    }

    func toggleUpdates() {
        if isUpdating { stopUpdates() } else { startUpdates() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if isAuthorized && !isUpdating {
            startUpdates()
        }
    }
}
