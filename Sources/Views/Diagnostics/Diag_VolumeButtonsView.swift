import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_VolumeButtonsView: View {
    @State private var currentVolume: Float = 0
    @State private var volumeUpDetected = false
    @State private var volumeDownDetected = false
    @State private var pressCount = 0
    @State private var volumeHistory: [(Date, Float)] = []
    @State private var isMonitoring = false
    @State private var timer: Timer?
    @State private var lastVolume: Float = -1

    var body: some View {
        Form {
            Section("Volume Buttons") {
                VStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                    Text("Press volume buttons to test")
                        .font(.headline)
                    Text("Volume Up and Volume Down button detection")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Current Volume") {
                VStack(spacing: 8) {
                    Text(String(format: "%.0f%%", currentVolume * 100))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                    ProgressView(value: Double(currentVolume))
                        .tint(.blue)
                }
                .padding(.vertical, 8)
            }

            Section("Button Status") {
                LabeledContent("Volume Up") {
                    HStack {
                        Image(systemName: volumeUpDetected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(volumeUpDetected ? .green : .secondary)
                        Text(volumeUpDetected ? "Detected" : "Not pressed")
                            .font(.caption)
                    }
                }
                LabeledContent("Volume Down") {
                    HStack {
                        Image(systemName: volumeDownDetected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(volumeDownDetected ? .green : .secondary)
                        Text(volumeDownDetected ? "Detected" : "Not pressed")
                            .font(.caption)
                    }
                }
                LabeledContent("Total Presses") {
                    Text("\(pressCount)")
                        .monospacedDigit()
                }
            }

            Section("Volume History") {
                if volumeHistory.isEmpty {
                    Text("Press volume buttons to see changes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(volumeHistory.suffix(15).enumerated()), id: \.offset) { _, entry in
                        HStack {
                            Text(String(format: "%.0f%%", entry.1 * 100))
                                .font(.caption.monospaced())
                            Spacer()
                            Text(entry.0, style: .time)
                                .font(.caption2)
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
                Button {
                    volumeUpDetected = false
                    volumeDownDetected = false
                    pressCount = 0
                    volumeHistory.removeAll()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                }
            }
        }
        .navigationTitle("Volume Buttons")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        isMonitoring = true
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true)
        } catch {}
        lastVolume = session.outputVolume
        currentVolume = lastVolume

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let vol = AVAudioSession.sharedInstance().outputVolume
            if vol != lastVolume {
                if vol > lastVolume {
                    volumeUpDetected = true
                } else {
                    volumeDownDetected = true
                }
                pressCount += 1
                volumeHistory.append((Date(), vol))
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
