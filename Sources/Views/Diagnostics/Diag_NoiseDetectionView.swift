import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_NoiseDetectionView: View {
    @State private var audioRecorder: AVAudioRecorder?
    @State private var timer: Timer?
    @State private var isMonitoring = false
    @State private var currentDB: Float = -160
    @State private var noiseLevel: String = "Silent"
    @State private var noiseLevelColor: Color = .green
    @State private var samples: [Float] = []

    var body: some View {
        Form {
            Section("Ambient Noise") {
                VStack(spacing: 16) {
                    Image(systemName: iconForNoise)
                        .font(.system(size: 50))
                        .foregroundStyle(noiseLevelColor)
                        .animation(.easeInOut, value: noiseLevel)

                    Text(noiseLevel)
                        .font(.title2.bold())
                        .foregroundStyle(noiseLevelColor)

                    Text("\(currentDB, specifier: "%.1f") dB")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Noise Scale") {
                VStack(alignment: .leading, spacing: 8) {
                    NoiseScaleRow(label: "Silent", range: "< -50 dB", color: .green, isActive: currentDB < -50)
                    NoiseScaleRow(label: "Quiet", range: "-50 to -30 dB", color: .mint, isActive: currentDB >= -50 && currentDB < -30)
                    NoiseScaleRow(label: "Moderate", range: "-30 to -15 dB", color: .yellow, isActive: currentDB >= -30 && currentDB < -15)
                    NoiseScaleRow(label: "Loud", range: "-15 to -5 dB", color: .orange, isActive: currentDB >= -15 && currentDB < -5)
                    NoiseScaleRow(label: "Very Loud", range: "> -5 dB", color: .red, isActive: currentDB >= -5)
                }
            }

            if !samples.isEmpty {
                Section("Average (\(samples.count) samples)") {
                    let avg = samples.reduce(0, +) / Float(samples.count)
                    LabeledContent("Average Level") {
                        Text("\(avg, specifier: "%.1f") dB")
                            .monospacedDigit()
                    }
                }
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "ear.badge.waveform")
                        Text(isMonitoring ? "Stop" : "Start Noise Detection")
                    }
                }
            }
        }
        .navigationTitle("Noise Detection")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopMonitoring() }
    }

    private var iconForNoise: String {
        if currentDB < -50 { return "speaker.slash.fill" }
        if currentDB < -30 { return "speaker.fill" }
        if currentDB < -15 { return "speaker.wave.1.fill" }
        if currentDB < -5 { return "speaker.wave.2.fill" }
        return "speaker.wave.3.fill"
    }

    private func classifyNoise(_ db: Float) {
        if db < -50 {
            noiseLevel = "Silent"
            noiseLevelColor = .green
        } else if db < -30 {
            noiseLevel = "Quiet"
            noiseLevelColor = .mint
        } else if db < -15 {
            noiseLevel = "Moderate"
            noiseLevelColor = .yellow
        } else if db < -5 {
            noiseLevel = "Loud"
            noiseLevelColor = .orange
        } else {
            noiseLevel = "Very Loud"
            noiseLevelColor = .red
        }
    }

    private func startMonitoring() {
        samples.removeAll()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch { return }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("diag_noise.m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        guard let recorder = try? AVAudioRecorder(url: url, settings: settings) else { return }
        recorder.isMeteringEnabled = true
        recorder.record()
        audioRecorder = recorder
        isMonitoring = true

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            recorder.updateMeters()
            let avg = recorder.averagePower(forChannel: 0)
            currentDB = avg
            samples.append(avg)
            classifyNoise(avg)
        }
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isMonitoring = false
    }
}

private struct NoiseScaleRow: View {
    let label: String
    let range: String
    let color: Color
    let isActive: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.subheadline)
                .fontWeight(isActive ? .bold : .regular)
            Spacer()
            Text(range)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .opacity(isActive ? 1.0 : 0.5)
    }
}
