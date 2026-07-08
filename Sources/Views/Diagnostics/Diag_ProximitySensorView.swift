import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct Diag_ProximitySensorView: View {
    @State private var isProximityActive = false
    @State private var proximityState = false
    @State private var detectionCount = 0
    @State private var isMonitoring = false

    var body: some View {
        Form {
            Section("Proximity Sensor") {
                VStack(spacing: 16) {
                    Image(systemName: proximityState ? "hand.raised.fill" : "hand.raised.slash.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(proximityState ? .green : .secondary)
                        .animation(.spring(response: 0.3), value: proximityState)

                    Text(proximityState ? "Object Detected" : "No Object Detected")
                        .font(.title3.bold())
                        .foregroundStyle(proximityState ? .green : .secondary)

                    Text("Detections: \(detectionCount)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
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

                if detectionCount > 0 {
                    Button("Reset Counter") {
                        detectionCount = 0
                    }
                }
            }

            Section {
                Text("The proximity sensor detects when an object (like your hand or face) is near the device screen. Place your hand over the top of the screen to test.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Proximity Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = true
        isMonitoring = true
        NotificationCenter.default.addObserver(forName: UIDevice.proximityStateDidChangeNotification, object: nil, queue: .main) { _ in
            proximityState = UIDevice.current.proximityState
            if proximityState { detectionCount += 1 }
        }
    }

    private func stopMonitoring() {
        UIDevice.current.isProximityMonitoringEnabled = false
        isMonitoring = false
        NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
        proximityState = false
    }
}
