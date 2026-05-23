import SwiftUI
import AVFoundation

struct Diag_HardwareButtonsView: View {
    @State private var volumeUpPressed = false
    @State private var volumeDownPressed = false
    @State private var silentSwitchOn = false
    @State private var currentVolume: Float = 0
    @State private var volumeHistory: [Float] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?

    var body: some View {
        Form {
            Section("Hardware Buttons") {
                VStack(spacing: 12) {
                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 52))
                        .foregroundStyle(.primary)
                    Text("Press hardware buttons to test")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Volume") {
                LabeledContent("Current Volume") {
                    Text(String(format: "%.0f%%", currentVolume * 100))
                        .monospacedDigit()
                }
                LabeledContent("Volume Up") {
                    Image(systemName: volumeUpPressed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(volumeUpPressed ? .green : .secondary)
                }
                LabeledContent("Volume Down") {
                    Image(systemName: volumeDownPressed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(volumeDownPressed ? .green : .secondary)
                }

                ProgressView(value: Double(currentVolume))
                    .tint(.blue)
            }

            Section("Silent Switch") {
                LabeledContent("Ringer/Silent") {
                    HStack {
                        Image(systemName: silentSwitchOn ? "bell.slash.fill" : "bell.fill")
                            .foregroundStyle(silentSwitchOn ? .orange : .green)
                        Text(silentSwitchOn ? "Silent" : "Ring")
                    }
                }
            }

            Section("Volume History") {
                if volumeHistory.isEmpty {
                    Text("Press volume buttons to see changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(volumeHistory.suffix(10).enumerated()), id: \.offset) { _, vol in
                        Text(String(format: "%.0f%%", vol * 100))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
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
            }
        }
        .navigationTitle("Hardware Buttons")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        isMonitoring = true
        var lastVolume: Float = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            let session = AVAudioSession.sharedInstance()
            let vol = session.outputVolume
            if vol != lastVolume {
                if vol > lastVolume { volumeUpPressed = true; volumeDownPressed = false }
                else { volumeDownPressed = true; volumeUpPressed = false }
                volumeHistory.append(vol)
                lastVolume = vol
            }
            currentVolume = vol
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
}
