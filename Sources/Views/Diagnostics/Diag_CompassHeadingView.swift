import SwiftUI
import CoreLocation

struct Diag_CompassHeadingView: View {
    @StateObject private var compassManager = CompassManager()

    var body: some View {
        Form {
            Section("Compass") {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 2)
                            .frame(width: 180, height: 180)

                        // Cardinal directions
                        ForEach(["N", "E", "S", "W"], id: \.self) { dir in
                            Text(dir)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(dir == "N" ? .red : .primary)
                                .offset(y: -80)
                                .rotationEffect(.degrees(cardinalAngle(dir)))
                        }

                        // Needle
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.red)
                            .rotationEffect(.degrees(-compassManager.magneticHeading))
                            .animation(.spring(response: 0.3), value: compassManager.magneticHeading)
                    }
                    .frame(width: 200, height: 200)

                    Text(String(format: "%.1f°", compassManager.magneticHeading))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                    Text(compassManager.cardinalDirection)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Heading Details") {
                LabeledContent("Magnetic Heading") {
                    Text(String(format: "%.2f°", compassManager.magneticHeading))
                        .monospacedDigit()
                }
                LabeledContent("True Heading") {
                    Text(String(format: "%.2f°", compassManager.trueHeading))
                        .monospacedDigit()
                }
                LabeledContent("Heading Accuracy") {
                    Text(String(format: "± %.1f°", compassManager.headingAccuracy))
                        .monospacedDigit()
                        .foregroundStyle(compassManager.headingAccuracy < 10 ? .green : .orange)
                }
                LabeledContent("Magnetic Declination") {
                    let declination = compassManager.trueHeading - compassManager.magneticHeading
                    Text(String(format: "%+.2f°", declination))
                        .monospacedDigit()
                }
            }

            Section("Raw Magnetic Field") {
                LabeledContent("X") {
                    Text(String(format: "%.2f μT", compassManager.magneticFieldX))
                        .monospacedDigit()
                        .foregroundStyle(.red)
                }
                LabeledContent("Y") {
                    Text(String(format: "%.2f μT", compassManager.magneticFieldY))
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
                LabeledContent("Z") {
                    Text(String(format: "%.2f μT", compassManager.magneticFieldZ))
                        .monospacedDigit()
                        .foregroundStyle(.blue)
                }
                LabeledContent("Magnitude") {
                    let mag = sqrt(pow(compassManager.magneticFieldX, 2) + pow(compassManager.magneticFieldY, 2) + pow(compassManager.magneticFieldZ, 2))
                    Text(String(format: "%.2f μT", mag))
                        .monospacedDigit()
                }
            }

            Section("Sensor Status") {
                LabeledContent("Heading Available") {
                    Text(CLLocationManager.headingAvailable() ? "Yes" : "No")
                        .foregroundStyle(CLLocationManager.headingAvailable() ? .green : .red)
                }
                LabeledContent("Calibration") {
                    Text(compassManager.headingAccuracy < 0 ? "Needs Calibration" : "Calibrated")
                        .foregroundStyle(compassManager.headingAccuracy < 0 ? .red : .green)
                }
            }

            Section {
                Button {
                    compassManager.toggleUpdates()
                } label: {
                    HStack {
                        Image(systemName: compassManager.isUpdating ? "stop.circle.fill" : "location.north.fill")
                        Text(compassManager.isUpdating ? "Stop" : "Start Compass")
                    }
                }
            }
        }
        .navigationTitle("Compass Heading")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { compassManager.startUpdates() }
        .onDisappear { compassManager.stopUpdates() }
    }

    private func cardinalAngle(_ direction: String) -> Double {
        switch direction {
        case "N": return 0
        case "E": return 90
        case "S": return 180
        case "W": return 270
        default: return 0
        }
    }
}

final class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var magneticHeading: Double = 0
    @Published var trueHeading: Double = 0
    @Published var headingAccuracy: Double = 0
    @Published var magneticFieldX: Double = 0
    @Published var magneticFieldY: Double = 0
    @Published var magneticFieldZ: Double = 0
    @Published var isUpdating = false

    var cardinalDirection: String {
        let heading = magneticHeading
        switch heading {
        case 0..<22.5, 337.5..<360: return "North"
        case 22.5..<67.5: return "Northeast"
        case 67.5..<112.5: return "East"
        case 112.5..<157.5: return "Southeast"
        case 157.5..<202.5: return "South"
        case 202.5..<247.5: return "Southwest"
        case 247.5..<292.5: return "West"
        case 292.5..<337.5: return "Northwest"
        default: return "N/A"
        }
    }

    override init() {
        super.init()
        manager.delegate = self
    }

    func startUpdates() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
        isUpdating = true
    }

    func stopUpdates() {
        manager.stopUpdatingHeading()
        isUpdating = false
    }

    func toggleUpdates() {
        if isUpdating { stopUpdates() } else { startUpdates() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        magneticHeading = newHeading.magneticHeading
        trueHeading = newHeading.trueHeading
        headingAccuracy = newHeading.headingAccuracy
        magneticFieldX = newHeading.x
        magneticFieldY = newHeading.y
        magneticFieldZ = newHeading.z
    }
}
