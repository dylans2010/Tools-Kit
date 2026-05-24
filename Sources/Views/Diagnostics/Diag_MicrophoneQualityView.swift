import SwiftUI
import AVFoundation
import Accelerate

struct Diag_MicrophoneQualityView: View {
    @State private var audioEngine = AVAudioEngine()
    @State private var isRecording = false
    @State private var decibelLevel: Float = -160
    @State private var peakLevel: Float = -160
    @State private var noiseFloor: Float = -160
    @State private var signalToNoise: Float = 0
    @State private var sampleRate: Double = 0
    @State private var channelCount: Int = 0
    @State private var clipCount = 0
    @State private var levelHistory: [Float] = []
    @State private var statusText = "Tap Start to analyze microphone"
    @State private var testDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var hasPermission = false

    var body: some View {
        Form {
            Section("Microphone Info") {
                LabeledContent("Sample Rate") {
                    Text(sampleRate > 0 ? String(format: "%.0f Hz", sampleRate) : "—")
                        .monospacedDigit()
                }
                LabeledContent("Channels") {
                    Text(channelCount > 0 ? "\(channelCount)" : "—")
                        .monospacedDigit()
                }
                LabeledContent("Permission") {
                    Text(hasPermission ? "Granted" : "Not Granted")
                        .foregroundStyle(hasPermission ? .green : .red)
                }
            }

            Section("Live Levels") {
                VStack(spacing: 12) {
                    levelBar(label: "Current", value: decibelLevel, color: levelColor(decibelLevel))
                    levelBar(label: "Peak", value: peakLevel, color: .red)
                    levelBar(label: "Noise Floor", value: noiseFloor, color: .yellow)
                }
                .padding(.vertical, 4)

                LabeledContent("Signal-to-Noise") {
                    Text(signalToNoise > 0 ? String(format: "%.1f dB", signalToNoise) : "—")
                        .monospacedDigit()
                        .foregroundStyle(snrColor)
                }
                LabeledContent("Clipping Events") {
                    Text("\(clipCount)")
                        .monospacedDigit()
                        .foregroundStyle(clipCount > 0 ? .red : .green)
                }
                LabeledContent("Duration") {
                    Text(String(format: "%.1f s", testDuration))
                        .monospacedDigit()
                }
            }

            if !levelHistory.isEmpty {
                Section("Level History") {
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(levelHistory.suffix(60).indices, id: \.self) { i in
                            let normalized = max(0, min(1, (levelHistory[i] + 60) / 60))
                            RoundedRectangle(cornerRadius: 1)
                                .fill(levelColor(levelHistory[i]))
                                .frame(height: CGFloat(normalized) * 50)
                        }
                    }
                    .frame(height: 50)
                    .padding(.vertical, 4)
                }
            }

            Section("Quality Assessment") {
                if testDuration > 2 {
                    qualityRow("Noise Floor", noiseFloor < -40 ? "Good" : noiseFloor < -20 ? "Fair" : "Poor",
                               noiseFloor < -40 ? .green : noiseFloor < -20 ? .yellow : .red)
                    qualityRow("SNR", signalToNoise > 30 ? "Excellent" : signalToNoise > 15 ? "Good" : "Poor",
                               signalToNoise > 30 ? .green : signalToNoise > 15 ? .yellow : .red)
                    qualityRow("Clipping", clipCount == 0 ? "None" : "\(clipCount) events",
                               clipCount == 0 ? .green : .red)
                    qualityRow("Sample Rate", sampleRate >= 44100 ? "HD" : "Standard",
                               sampleRate >= 44100 ? .green : .yellow)
                } else {
                    Text("Record for at least 2 seconds for quality assessment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    if isRecording { stopRecording() } else { startRecording() }
                } label: {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        Text(isRecording ? "Stop Recording" : "Start Quality Test")
                    }
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Microphone Quality")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkPermission() }
        .onDisappear { stopRecording() }
    }

    private func levelBar(label: String, value: Float, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .frame(width: 70, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.tertiarySystemGroupedBackground))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(0, geo.size.width * CGFloat(max(0, min(1, (value + 60) / 60)))))
                        .animation(.linear(duration: 0.1), value: value)
                }
            }
            .frame(height: 12)
            Text(String(format: "%.0f dB", value))
                .font(.caption.monospacedDigit())
                .frame(width: 50, alignment: .trailing)
        }
    }

    private func qualityRow(_ label: String, _ value: String, _ color: Color) -> some View {
        LabeledContent(label) {
            Text(value)
                .foregroundStyle(color)
        }
    }

    private func levelColor(_ db: Float) -> Color {
        if db > -3 { return .red }
        if db > -12 { return .yellow }
        return .green
    }

    private var snrColor: Color {
        if signalToNoise > 30 { return .green }
        if signalToNoise > 15 { return .yellow }
        return .red
    }

    private func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            hasPermission = true
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async { hasPermission = granted }
            }
        default:
            hasPermission = false
        }
    }

    private func startRecording() {
        guard hasPermission else {
            statusText = "Microphone permission required"
            return
        }

        peakLevel = -160
        noiseFloor = 0
        clipCount = 0
        levelHistory = []
        testDuration = 0

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement)
            try AVAudioSession.sharedInstance().setActive(true)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            sampleRate = format.sampleRate
            channelCount = Int(format.channelCount)

            var noiseFloorSamples: [Float] = []

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameCount = Int(buffer.frameLength)

                var rms: Float = 0
                vDSP_measqv(channelData, 1, &rms, vDSP_Length(frameCount))
                rms = sqrt(rms)

                let db = 20 * log10(max(rms, 0.000001))

                var peak: Float = 0
                vDSP_maxv(channelData, 1, &peak, vDSP_Length(frameCount))

                DispatchQueue.main.async {
                    decibelLevel = db
                    levelHistory.append(db)
                    if db > peakLevel { peakLevel = db }
                    if peak > 0.99 { clipCount += 1 }

                    noiseFloorSamples.append(db)
                    if noiseFloorSamples.count > 10 {
                        let sorted = noiseFloorSamples.sorted()
                        noiseFloor = sorted[sorted.count / 4]
                        signalToNoise = peakLevel - noiseFloor
                    }
                }
            }

            try audioEngine.start()
            isRecording = true
            statusText = "Recording..."

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                testDuration += 0.1
            }
        } catch {
            statusText = "Error: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        statusText = "Test completed — \(String(format: "%.1f", testDuration))s recorded"
    }
}
