import SwiftUI
import CoreLocation

struct Diag_LocationHistoryView: View {
    @StateObject private var manager = LocationHistoryManager()

    var body: some View {
        Form {
            Section("Tracking Status") {
                LabeledContent("Authorization") {
                    Text(manager.authStatus)
                        .foregroundStyle(manager.isAuthorized ? .green : .orange)
                }
                LabeledContent("Tracking") {
                    Text(manager.isTracking ? "Active" : "Inactive")
                        .foregroundStyle(manager.isTracking ? .green : .secondary)
                }
                LabeledContent("Points Recorded") { Text("\(manager.locations.count)").monospacedDigit() }
                LabeledContent("Distance Traveled") {
                    Text(String(format: "%.0f m", manager.totalDistance))
                        .monospacedDigit()
                }
            }

            if let current = manager.locations.last {
                Section("Current Position") {
                    LabeledContent("Latitude") {
                        Text(String(format: "%.6f°", current.coordinate.latitude))
                            .monospacedDigit()
                    }
                    LabeledContent("Longitude") {
                        Text(String(format: "%.6f°", current.coordinate.longitude))
                            .monospacedDigit()
                    }
                    LabeledContent("Accuracy") {
                        Text(String(format: "± %.1f m", current.horizontalAccuracy))
                            .monospacedDigit()
                    }
                    LabeledContent("Speed") {
                        Text(current.speed >= 0 ? String(format: "%.1f m/s (%.1f km/h)", current.speed, current.speed * 3.6) : "N/A")
                            .monospacedDigit()
                    }
                    LabeledContent("Updated") {
                        Text(current.timestamp, style: .time)
                    }
                }
            }

            Section("Significant Locations") {
                LabeledContent("Significant Monitoring") {
                    Text(CLLocationManager.significantLocationChangeMonitoringAvailable() ? "Available" : "Not Available")
                        .foregroundStyle(CLLocationManager.significantLocationChangeMonitoringAvailable() ? .green : .red)
                }
                LabeledContent("Region Monitoring") {
                    Text(CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) ? "Available" : "Not Available")
                }
                LabeledContent("Visit Monitoring") {
                    Text("Available")
                        .foregroundStyle(.green)
                }
            }

            if !manager.locations.isEmpty {
                Section("Location History (\(manager.locations.count))") {
                    ForEach(Array(manager.locations.suffix(15).enumerated()), id: \.offset) { idx, loc in
                        HStack {
                            Text("#\(manager.locations.count - 14 + idx)")
                                .font(.caption.monospacedDigit())
                                .frame(width: 30, alignment: .leading)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.5f, %.5f", loc.coordinate.latitude, loc.coordinate.longitude))
                                    .font(.caption.monospaced())
                                Text(loc.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Text(String(format: "±%.0fm", loc.horizontalAccuracy))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    manager.toggleTracking()
                } label: {
                    HStack {
                        Image(systemName: manager.isTracking ? "location.slash.fill" : "location.fill")
                        Text(manager.isTracking ? "Stop Tracking" : "Start Tracking")
                    }
                }
                if !manager.isAuthorized {
                    Button("Request Permission") {
                        manager.requestPermission()
                    }
                }
                if !manager.locations.isEmpty {
                    Button("Clear History") {
                        manager.clearHistory()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Location History")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { manager.stopTracking() }
    }
}

final class LocationHistoryManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var locations: [CLLocation] = []
    @Published var isTracking = false
    @Published var totalDistance: CLLocationDistance = 0

    var authStatus: String {
        switch manager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }

    var isAuthorized: Bool {
        manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        guard isAuthorized else { requestPermission(); return }
        manager.startUpdatingLocation()
        isTracking = true
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        isTracking = false
    }

    func toggleTracking() {
        if isTracking { stopTracking() } else { startTracking() }
    }

    func clearHistory() {
        locations = []
        totalDistance = 0
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations newLocations: [CLLocation]) {
        for loc in newLocations {
            if let last = locations.last {
                totalDistance += loc.distance(from: last)
            }
            locations.append(loc)
            if locations.count > 500 { locations.removeFirst() }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if isAuthorized && !isTracking {
            startTracking()
        }
    }
}
