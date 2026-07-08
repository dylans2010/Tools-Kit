import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif
import Accelerate

struct Diag_GlassBreakDetectView: View {
    @State private var audioEngine = AVAudioEngine()
    @State private var isListening = false
    @State private var hasPermission = false
    @State private var currentDB: Float = -160
    @State private var frequency: Float = 0
    @State private var detectionCount = 0
    @State private var events: [DetectionEvent] = []
    @State private var sensitivityThreshold: Float = -10
    @State private var frequencyThreshold: Float = 2000
    @State private var statusText = "Ready to monitor"
    @State private var levelHistory: [Float] = []

    struct DetectionEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let peakDB: Float
        let frequency: Float
        let classification: String
    }

    var body: some View {
        Form {
            Section("Monitor") {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: CGFloat(max(0, min(1, (currentDB + 60) / 60))))
                            .stroke(isListening ? (currentDB > sensitivityThreshold ? .red : .green) : .gray,
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: currentDB)
                        VStack(spacing: 2) {
                            Image(systemName: isListening ? "ear.fill" : "ear")
                                .font(.title2)
                                .foregroundStyle(isListening ? .green : .secondary)
                            Text(String(format: "%.0f dB", currentDB))
                                .font(.title3.monospacedDigit().bold())
                            Text(String(format: "%.0f Hz", frequency))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 140, height: 140)

                    if !levelHistory.isEmpty {
                        HStack(alignment: .bottom, spacing: 1) {
                            ForEach(levelHistory.suffix(80).indices, id: \.self) { i in
                                let normalized = max(0, min(1, (levelHistory[i] + 60) / 60))
                                Rectangle()
                                    .fill(levelHistory[i] > sensitivityThreshold ? Color.red : Color.green)
                                    .frame(height: CGFloat(normalized) * 30)
                            }
                        }
                        .frame(height: 30)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Settings") {
                VStack(alignment: .leading) {
                    Text("Volume Threshold: \(Int(sensitivityThreshold)) dB")
                        .font(.subheadline)
                    Slider(value: $sensitivityThreshold, in: -30...0, step: 1)
                        .tint(.orange)
                }
                VStack(alignment: .leading) {
                    Text("Frequency Threshold: \(Int(frequencyThreshold)) Hz")
                        .font(.subheadline)
                    Slider(value: $frequencyThreshold, in: 500...8000, step: 100)
                        .tint(.purple)
                }
            }

            Section("Detection Log (\(detectionCount))") {
                if events.isEmpty {
                    Text("No events detected yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(events.prefix(20), id: \.id) { event in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            VStack(alignment: .leading) {
                                Text(event.classification)
                                    .font(.subheadline.weight(.medium))
                                Text("\(String(format: "%.0f dB", event.peakDB)) at \(String(format: "%.0f Hz", event.frequency))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(event.timestamp, style: .time)
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }

            Section {
                Button {
                    if isListening { stopListening() } else { startListening() }
                } label: {
                    HStack {
                        Image(systemName: isListening ? "stop.circle.fill" : "waveform.badge.magnifyingglass")
                        Text(isListening ? "Stop Monitoring" : "Start Monitoring")
                    }
                }

                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } footer: {
                Text("Monitors ambient sound for sudden loud impacts, which may indicate screen or glass damage events.")
            }
        }
        .navigationTitle("Impact Detection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkPermission() }
        .onDisappear { stopListening() }
    }

    private func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: hasPermission = true
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async { hasPermission = granted }
            }
        default: hasPermission = false
        }
    }

    private func startListening() {
        guard hasPermission else {
            statusText = "Microphone permission required"
            return
        }

        levelHistory = []

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement)
            try AVAudioSession.sharedInstance().setActive(true)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in
                guard let channelData = buffer.floatChannelData?[0] else { return }
                let frameCount = Int(buffer.frameLength)

                // Calculate RMS and dB
                var rms: Float = 0
                vDSP_measqv(channelData, 1, &rms, vDSP_Length(frameCount))
                rms = sqrt(rms)
                let db = 20 * log10(max(rms, 0.000001))

                // Estimate dominant frequency via zero-crossing rate
                var zeroCrossings = 0
                for i in 1..<frameCount {
                    if (channelData[i - 1] > 0 && channelData[i] <= 0) || (channelData[i - 1] <= 0 && channelData[i] > 0) {
                        zeroCrossings += 1
                    }
                }
                let estimatedFreq = Float(zeroCrossings) * Float(format.sampleRate) / Float(2 * frameCount)

                DispatchQueue.main.async {
                    currentDB = db
                    frequency = estimatedFreq
                    levelHistory.append(db)

                    // Detect impact events
                    if db > sensitivityThreshold && estimatedFreq > frequencyThreshold {
                        let classification = classifyEvent(db: db, freq: estimatedFreq)
                        let event = DetectionEvent(
                            timestamp: Date(),
                            peakDB: db,
                            frequency: estimatedFreq,
                            classification: classification
                        )
                        events.insert(event, at: 0)
                        detectionCount += 1
                    }
                }
            }

            try audioEngine.start()
            isListening = true
            statusText = "Monitoring for impact sounds..."
        } catch {
            statusText = "Error: \(error.localizedDescription)"
        }
    }

    private func classifyEvent(db: Float, freq: Float) -> String {
        if freq > 5000 && db > -5 {
            return "High-frequency impact — possible glass crack"
        } else if freq > 3000 && db > -10 {
            return "Sharp impact detected"
        } else if db > -5 {
            return "Loud impact detected"
        } else {
            return "Moderate impact"
        }
    }

    private func stopListening() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isListening = false
        statusText = "Monitoring stopped — \(detectionCount) events detected"
    }
}
