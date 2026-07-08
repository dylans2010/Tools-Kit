import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct Diag_MicInputLevelView: View {
    @State private var audioRecorder: AVAudioRecorder?
    @State private var timer: Timer?
    @State private var level: Float = -160
    @State private var peakLevel: Float = -160
    @State private var isMonitoring = false
    @State private var levelHistory: [Float] = Array(repeating: -160, count: 60)

    var body: some View {
        Form {
            Section("Input Level") {
                VStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.tertiarySystemGroupedBackground))
                            .frame(height: 30)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(levelColor)
                                .frame(width: max(0, geo.size.width * CGFloat(normalizedLevel)), height: 30)
                                .animation(.linear(duration: 0.1), value: level)
                        }
                        .frame(height: 30)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Level")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(level, specifier: "%.1f") dB")
                                .font(.title3.monospacedDigit().bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Peak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(peakLevel, specifier: "%.1f") dB")
                                .font(.title3.monospacedDigit().bold())
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Waveform") {
                Canvas { context, size in
                    let barWidth = size.width / CGFloat(levelHistory.count)
                    for (index, value) in levelHistory.enumerated() {
                        let normalized = CGFloat((value + 160) / 160)
                        let height = normalized * size.height
                        let rect = CGRect(
                            x: CGFloat(index) * barWidth,
                            y: size.height - height,
                            width: barWidth - 1,
                            height: height
                        )
                        context.fill(Path(rect), with: .color(.blue.opacity(0.7)))
                    }
                }
                .frame(height: 120)
            }

            Section {
                Button {
                    if isMonitoring { stopMonitoring() } else { startMonitoring() }
                } label: {
                    HStack {
                        Image(systemName: isMonitoring ? "stop.circle.fill" : "mic.circle.fill")
                        Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                }

                if peakLevel > -160 {
                    Button("Reset Peak") {
                        peakLevel = -160
                    }
                }
            }
        }
        .navigationTitle("Mic Input Level")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopMonitoring() }
    }

    private var normalizedLevel: Float {
        max(0, min(1, (level + 60) / 60))
    }

    private var levelColor: Color {
        if normalizedLevel > 0.8 { return .red }
        if normalizedLevel > 0.5 { return .yellow }
        return .green
    }

    private func startMonitoring() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch { return }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("diag_mic_level.m4a")
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

        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            recorder.updateMeters()
            let avg = recorder.averagePower(forChannel: 0)
            level = avg
            if avg > peakLevel { peakLevel = avg }
            levelHistory.append(avg)
            if levelHistory.count > 60 { levelHistory.removeFirst() }
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
