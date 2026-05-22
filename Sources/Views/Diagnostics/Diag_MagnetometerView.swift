import SwiftUI
import CoreMotion

struct Diag_MagnetometerView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var x: Double = 0
    @State private var y: Double = 0
    @State private var z: Double = 0
    @State private var isActive = false
    @State private var magnitude: Double = 0

    var body: some View {
        Form {
            Section("Magnetic Field (microteslas)") {
                VStack(spacing: 12) {
                    MagAxisRow(label: "X", value: x, color: .red)
                    MagAxisRow(label: "Y", value: y, color: .green)
                    MagAxisRow(label: "Z", value: z, color: .blue)
                }
                .padding(.vertical, 4)
            }

            Section("Compass") {
                VStack(spacing: 8) {
                    let heading = atan2(y, x) * 180.0 / .pi
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                        .rotationEffect(.degrees(-heading))
                        .animation(.spring(response: 0.3), value: heading)

                    Text("\(normalizedHeading(heading), specifier: "%.0f")°")
                        .font(.title.monospacedDigit().bold())

                    Text(compassDirection(heading))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Info") {
                LabeledContent("Available") {
                    Text(service.isMagnetometerAvailable ? "Yes" : "No")
                        .foregroundStyle(service.isMagnetometerAvailable ? .green : .red)
                }
                LabeledContent("Field Magnitude") {
                    Text("\(magnitude, specifier: "%.1f") µT")
                        .monospacedDigit()
                }
            }

            Section {
                Button {
                    if isActive { stopSensor() } else { startSensor() }
                } label: {
                    HStack {
                        Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                        Text(isActive ? "Stop" : "Start Magnetometer")
                    }
                }
            }
        }
        .navigationTitle("Magnetometer")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopSensor() }
    }

    private func startSensor() {
        isActive = true
        service.startMagnetometer { data in
            guard let data = data else { return }
            x = data.magneticField.x
            y = data.magneticField.y
            z = data.magneticField.z
            magnitude = sqrt(x*x + y*y + z*z)
        }
    }

    private func stopSensor() {
        service.stopMagnetometer()
        isActive = false
    }

    private func normalizedHeading(_ heading: Double) -> Double {
        var h = heading
        if h < 0 { h += 360 }
        return h
    }

    private func compassDirection(_ heading: Double) -> String {
        let h = normalizedHeading(heading)
        switch h {
        case 337.5...360, 0..<22.5: return "North"
        case 22.5..<67.5: return "Northeast"
        case 67.5..<112.5: return "East"
        case 112.5..<157.5: return "Southeast"
        case 157.5..<202.5: return "South"
        case 202.5..<247.5: return "Southwest"
        case 247.5..<292.5: return "West"
        case 292.5..<337.5: return "Northwest"
        default: return "—"
        }
    }
}

private struct MagAxisRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 24)
            Spacer()
            Text("\(value, specifier: "%+.1f") µT")
                .font(.system(.body, design: .monospaced))
        }
    }
}
