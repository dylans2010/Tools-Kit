import SwiftUI
import CoreLocation

struct Diag_HeadingView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
                    .frame(width: 250, height: 250)

                // Compass markings
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 2, height: 10)
                        .offset(y: -120)
                        .rotationEffect(.degrees(Double(i) * 45))
                }

                // Cardinal directions
                Text("N").position(x: 125, y: 15).font(.headline).foregroundStyle(.red)
                Text("S").position(x: 125, y: 235).font(.headline)
                Text("E").position(x: 235, y: 125).font(.headline)
                Text("W").position(x: 15, y: 125).font(.headline)

                // Needle
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.red)
                    .rotationEffect(.degrees(service.lastHeading?.magneticHeading ?? 0))
            }
            .frame(width: 250, height: 250)
            .padding(.top, 40)

            List {
                Section("Heading Data") {
                    LabeledContent("Magnetic Heading") {
                        Text("\(service.lastHeading?.magneticHeading ?? 0, specifier: "%.1f")°")
                            .monospacedDigit()
                    }
                    LabeledContent("True Heading") {
                        if let trueHeading = service.lastHeading?.trueHeading, trueHeading >= 0 {
                            Text("\(trueHeading, specifier: "%.1f")°")
                        } else {
                            Text("N/A")
                        }
                    }
                    LabeledContent("Accuracy") {
                        Text("±\(service.lastHeading?.headingAccuracy ?? 0, specifier: "%.1f")°")
                    }
                }

                Section("Calibration") {
                    LabeledContent("Status") {
                        Text("Calibrated")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .navigationTitle("Compass & Heading")
        .onAppear {
            service.startLocationUpdates()
        }
    }
}
