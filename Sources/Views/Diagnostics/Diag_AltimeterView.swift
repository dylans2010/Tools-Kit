import SwiftUI
import CoreMotion

struct Diag_AltimeterView: View {
    @State private var relativeAltitude: Double = 0
    @State private var pressure: Double = 0
    @State private var isMonitoring = false
    @State private var startAltitude: Double = 0
    @State private var maxAltitude: Double = 0
    @State private var minAltitude: Double = 0
    @State private var history: [AltitudeSample] = []
    private let altimeter = CMAltimeter()

    struct AltitudeSample: Identifiable {
        let id = UUID()
        let timestamp: Date
        let altitude: Double
        let pressure: Double
    }

    var body: some View {
        Form {
            Section("Altitude") {
                VStack(spacing: 8) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                    Text(String(format: "%.2f m", relativeAltitude))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                    Text("Relative Altitude Change")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Atmospheric Pressure") {
                LabeledContent("Pressure") {
                    Text(String(format: "%.2f kPa", pressure))
                        .monospacedDigit()
                }
                LabeledContent("Approx. Altitude (ISA)") {
                    Text(String(format: "%.0f m", estimatedAbsoluteAltitude()))
                        .monospacedDigit()
                }
                LabeledContent("Weather") {
                    Text(pressureWeather)
                        .foregroundStyle(pressureWeatherColor)
                }
            }

            Section("Statistics") {
                LabeledContent("Max Change") {
                    Text(String(format: "+%.2f m", maxAltitude))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
                LabeledContent("Min Change") {
                    Text(String(format: "%.2f m", minAltitude))
                        .monospacedDigit()
                        .foregroundStyle(.red)
                }
                LabeledContent("Total Range") {
                    Text(String(format: "%.2f m", maxAltitude - minAltitude))
                        .monospacedDigit()
                }
                LabeledContent("Samples") {
                    Text("\(history.count)")
                }
            }

            Section("Sensor Status") {
                LabeledContent("Altimeter Available") {
                    Text(CMAltimeter.isRelativeAltitudeAvailable() ? "Yes" : "No")
                        .foregroundStyle(CMAltimeter.isRelativeAltitudeAvailable() ? .green : .red)
                }
                LabeledContent("Authorization") {
                    Text(authorizationStatus)
                }
            }

            if !history.isEmpty {
                Section("Recent Readings") {
                    ForEach(history.suffix(10)) { sample in
                        HStack {
                            Text(sample.timestamp, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.2f m", sample.altitude))
                                .font(.caption.monospacedDigit())
                            Text(String(format: "%.1f kPa", sample.pressure))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "play.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
                if isMonitoring {
                    Button("Reset Baseline") {
                        startAltitude = relativeAltitude
                        maxAltitude = 0
                        minAltitude = 0
                    }
                }
            }
        }
        .navigationTitle("Altimeter")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private var pressureWeather: String {
        if pressure > 102 { return "High (Clear)" }
        if pressure > 100 { return "Normal" }
        if pressure > 98 { return "Low (Cloudy)" }
        return "Very Low (Storm)"
    }

    private var pressureWeatherColor: Color {
        if pressure > 102 { return .green }
        if pressure > 100 { return .blue }
        if pressure > 98 { return .orange }
        return .red
    }

    private var authorizationStatus: String {
        switch CMAltimeter.authorizationStatus() {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }

    private func estimatedAbsoluteAltitude() -> Double {
        guard pressure > 0 else { return 0 }
        // ISA formula: altitude = 44330 * (1 - (P/P0)^(1/5.255))
        let p0 = 101.325 // sea level pressure kPa
        return 44330 * (1 - pow(pressure / p0, 1 / 5.255))
    }

    private func startMonitoring() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        isMonitoring = true

        altimeter.startRelativeAltitudeUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            relativeAltitude = data.relativeAltitude.doubleValue
            pressure = data.pressure.doubleValue

            let adjusted = relativeAltitude - startAltitude
            if adjusted > maxAltitude { maxAltitude = adjusted }
            if adjusted < minAltitude { minAltitude = adjusted }

            history.append(AltitudeSample(timestamp: Date(), altitude: relativeAltitude, pressure: pressure))
            if history.count > 100 { history.removeFirst() }
        }
    }

    private func stopMonitoring() {
        altimeter.stopRelativeAltitudeUpdates()
        isMonitoring = false
    }
}
