import SwiftUI

struct Diag_AltimeterView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var relativeAltitude: Double = 0
    @State private var pressure: Double = 0

    var body: some View {
        List {
            Section("Live Metrics") {
                VStack(spacing: 20) {
                    HStack {
                        VStack {
                            Text("\(relativeAltitude, specifier: "%.2f") m")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("Relative Altitude")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text("\(pressure, specifier: "%.2f") hPa")
                                .font(.system(size: 24, weight: .semibold, design: .rounded))
                            Text("Pressure")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()

                    GraphPlaceholder()
                        .frame(height: 100)
                }
            }

            Section("Reference Data") {
                LabeledContent("Base Altitude", value: "0.00 m")
                LabeledContent("Current Floor", value: "Available on iPhone 6+")
            }

            Section {
                Button("Reset Reference") {
                    relativeAltitude = 0
                }
            }
        }
        .navigationTitle("Altimeter")
        .onAppear {
            // Simulated updates
            pressure = 1013.25
        }
    }
}

struct GraphPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
            Text("Altitude Graph")
                .foregroundStyle(.tertiary)
        }
    }
}
