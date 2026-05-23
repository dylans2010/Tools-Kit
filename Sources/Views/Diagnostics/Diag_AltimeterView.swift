import SwiftUI
import CoreMotion

struct Diag_AltimeterView: View {
    @State private var relativeAltitude: Double = 0
    @State private var pressure: Double = 0
    @State private var isAvailable = false
    @State private var isMonitoring = false
    private let altimeter = CMAltimeter()

    var body: some View {
        Form {
            Section("Altitude Tracker") {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text(String(format: "%.2f m", relativeAltitude))
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                        Text("Relative Change")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: relativeAltitude, total: 100)
                        .tint(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Atmospheric Pressure") {
                LabeledContent("Pressure") {
                    Text(String(format: "%.2f kPa", pressure)).monospacedDigit()
                }
            }

            Section("Status") {
                LabeledContent("Hardware Available", value: isAvailable ? "Yes" : "No")

                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "elevation")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }
                .disabled(!isAvailable)
            }

            Section {
                Text("The altimeter measures relative altitude changes and atmospheric pressure using the device's barometer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Altimeter")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isAvailable = CMAltimeter.isRelativeAltitudeAvailable()
        }
        .onDisappear {
            stopMonitoring()
        }
    }

    private func startMonitoring() {
        guard isAvailable else { return }
        isMonitoring = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { data, error in
            guard let data = data else { return }
            relativeAltitude = data.relativeAltitude.doubleValue
            pressure = data.pressure.doubleValue
        }
    }

    private func stopMonitoring() {
        altimeter.stopRelativeAltitudeUpdates()
        isMonitoring = false
    }
}
