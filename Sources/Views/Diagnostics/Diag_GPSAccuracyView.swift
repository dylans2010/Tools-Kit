import SwiftUI
import CoreLocation

struct Diag_GPSAccuracyView: View {
    @StateObject private var locationManager = GPSAccuracyManager()

    var body: some View {
        Form {
            Section("GPS Accuracy") {
                VStack(spacing: 12) {
                    Image(systemName: locationManager.isAuthorized ? "location.fill" : "location.slash.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(locationManager.isAuthorized ? .green : .secondary)
                    Text(locationManager.isAuthorized ? "GPS Active" : "Location Permission Required")
                        .font(.headline)
                    Text("Real-time GPS accuracy measurement with horizontal and vertical precision")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            if let location = locationManager.currentLocation {
                Section("Current Position") {
                    LabeledContent("Latitude") {
                        Text(String(format: "%.6f\u{00B0}", location.coordinate.latitude))
                            .font(.caption.monospaced())
                    }
                    LabeledContent("Longitude") {
                        Text(String(format: "%.6f\u{00B0}", location.coordinate.longitude))
                            .font(.caption.monospaced())
                    }
                    LabeledContent("Altitude") {
                        Text(String(format: "%.1f m", location.altitude))
                            .font(.caption.monospaced())
                    }
                }

                Section("Accuracy") {
                    LabeledContent("Horizontal Accuracy") {
                        Text(String(format: "%.1f m", location.horizontalAccuracy))
                            .font(.caption.monospaced())
                            .foregroundStyle(location.horizontalAccuracy < 10 ? .green : location.horizontalAccuracy < 50 ? .orange : .red)
                    }
                    LabeledContent("Vertical Accuracy") {
                        Text(String(format: "%.1f m", location.verticalAccuracy))
                            .font(.caption.monospaced())
                            .foregroundStyle(location.verticalAccuracy < 10 ? .green : location.verticalAccuracy < 50 ? .orange : .red)
                    }
                    LabeledContent("Speed") {
                        Text(location.speed >= 0 ? String(format: "%.1f m/s", location.speed) : "N/A")
                            .font(.caption.monospaced())
                    }
                    LabeledContent("Course") {
                        Text(location.course >= 0 ? String(format: "%.1f\u{00B0}", location.course) : "N/A")
                            .font(.caption.monospaced())
                    }
                    LabeledContent("Floor") {
                        Text(location.floor.map { "\($0.level)" } ?? "N/A")
                            .font(.caption.monospaced())
                    }
                }

                Section("Accuracy Rating") {
                    HStack {
                        Image(systemName: accuracyIcon(location.horizontalAccuracy))
                            .foregroundStyle(accuracyColor(location.horizontalAccuracy))
                        Text(accuracyLabel(location.horizontalAccuracy))
                            .font(.caption)
                    }
                }
            }

            Section("GPS Capabilities") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("GPS, GLONASS, Galileo, BeiDou, QZSS", systemImage: "globe").font(.caption)
                    Label("Dual-frequency GPS (L1 + L5) iPhone 14+", systemImage: "antenna.radiowaves.left.and.right").font(.caption)
                    Label("Precision Finding with UWB (iPhone 11+)", systemImage: "dot.radiowaves.left.and.right").font(.caption)
                    Label("A-GPS for faster time-to-first-fix", systemImage: "location.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { locationManager.startUpdating() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Refresh Location") }
                }
            }
        }
        .navigationTitle("GPS Accuracy")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { locationManager.startUpdating() }
    }

    private func accuracyIcon(_ accuracy: Double) -> String {
        if accuracy < 5 { return "checkmark.seal.fill" }
        if accuracy < 15 { return "checkmark.circle.fill" }
        if accuracy < 50 { return "exclamationmark.circle.fill" }
        return "xmark.circle.fill"
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy < 5 { return .green }
        if accuracy < 15 { return .blue }
        if accuracy < 50 { return .orange }
        return .red
    }

    private func accuracyLabel(_ accuracy: Double) -> String {
        if accuracy < 5 { return "Excellent (<5m)" }
        if accuracy < 15 { return "Good (<15m)" }
        if accuracy < 50 { return "Fair (<50m)" }
        return "Poor (>50m)"
    }
}

class GPSAccuracyManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var isAuthorized = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func startUpdating() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        isAuthorized = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        if isAuthorized { manager.startUpdatingLocation() }
    }
}
