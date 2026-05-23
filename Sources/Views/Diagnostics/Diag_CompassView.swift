import SwiftUI

struct Diag_CompassView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var isMonitoring = false

    var body: some View {
        Form {
            Section("Direction") {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemFill), lineWidth: 2)

                        // Compass needle
                        Capsule()
                            .fill(.red)
                            .frame(width: 4, height: 40)
                            .offset(y: -20)
                            .rotationEffect(.degrees(service.lastHeading?.magneticHeading ?? 0))

                        // Markers
                        ForEach(0..<4) { i in
                            Text(["N", "E", "S", "W"][i])
                                .font(.caption.bold())
                                .offset(y: -70)
                                .rotationEffect(.degrees(Double(i) * 90))
                        }
                    }
                    .frame(width: 160, height: 160)
                    .padding(.top)

                    VStack(spacing: 4) {
                        Text("\(Int(service.lastHeading?.magneticHeading ?? 0))°")
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                        Text("Magnetic North")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Heading Details") {
                LabeledContent("True North") {
                    if let trueHeading = service.lastHeading?.trueHeading, trueHeading >= 0 {
                        Text("\(Int(trueHeading))°").monospacedDigit()
                    } else {
                        Text("Unavailable")
                    }
                }
                LabeledContent("Accuracy") {
                    Text("±\(Int(service.lastHeading?.headingAccuracy ?? 0))°").monospacedDigit()
                }
            }

            Section {
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
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "safari.fill")
                        Text(isMonitoring ? "Stop Compass" : "Start Compass")
                    }
                }
            }
        }
        .navigationTitle("Compass")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            service.stopLocationUpdates()
        }
    }
}
