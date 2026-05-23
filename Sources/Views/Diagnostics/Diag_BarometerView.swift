import SwiftUI
import CoreMotion

struct Diag_BarometerView: View {
    @State private var pressure: Double = 0
    @State private var relativeAltitude: Double = 0
    @State private var isAvailable = false
    @State private var isMonitoring = false
    @State private var samples: [Double] = []
    private let altimeter = CMAltimeter()

    var body: some View {
        Form {
            Section("Barometric Pressure") {
                VStack(spacing: 12) {
                    Text(String(format: "%.1f", pressure))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("kPa")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Altitude Change") {
                LabeledContent("Relative Altitude") {
                    Text(String(format: "%.2f m", relativeAltitude)).monospacedDigit()
                }
                LabeledContent("Samples Collected") {
                    Text("\(samples.count)").monospacedDigit()
                }
            }

            Section("Status") {
                LabeledContent("Barometer Available") {
                    Text(isAvailable ? "Yes" : "No")
                        .foregroundStyle(isAvailable ? .green : .red)
                }
                LabeledContent("Monitoring") {
                    Text(isMonitoring ? "Active" : "Stopped")
                        .foregroundStyle(isMonitoring ? .green : .secondary)
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "barometer")
                        Text(isMonitoring ? "Stop" : "Start Monitoring")
                    }
                }
                .disabled(!isAvailable)
            }
        }
        .navigationTitle("Barometer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isAvailable = CMAltimeter.isRelativeAltitudeAvailable() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        guard isAvailable else { return }
        isMonitoring = true
        altimeter.startRelativeAltitudeUpdates(to: .main) { data, _ in
            guard let data = data else { return }
            pressure = data.pressure.doubleValue
            relativeAltitude = data.relativeAltitude.doubleValue
            samples.append(pressure)
        }
    }

    private func stopMonitoring() {
        altimeter.stopRelativeAltitudeUpdates()
        isMonitoring = false
    }
}
