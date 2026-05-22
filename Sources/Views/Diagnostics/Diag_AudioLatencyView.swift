import SwiftUI
import AVFoundation

struct Diag_AudioLatencyView: View {
    @State private var isMeasuring = false
    @State private var measurements: [Double] = []
    @State private var currentLatency: Double = 0

    var body: some View {
        Form {
            Section("Audio Latency") {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)

                    if !measurements.isEmpty {
                        Text("\(currentLatency, specifier: "%.1f") ms")
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                    } else {
                        Text("—")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(.secondary)
                    }

                    Text("Audio output buffer latency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Audio Session Info") {
                let session = AVAudioSession.sharedInstance()
                LabeledContent("Buffer Duration") {
                    Text("\(session.ioBufferDuration * 1000, specifier: "%.1f") ms")
                        .monospacedDigit()
                }
                LabeledContent("Sample Rate") {
                    Text("\(Int(session.sampleRate)) Hz")
                        .monospacedDigit()
                }
                LabeledContent("Output Latency") {
                    Text("\(session.outputLatency * 1000, specifier: "%.1f") ms")
                        .monospacedDigit()
                }
                LabeledContent("Input Latency") {
                    Text("\(session.inputLatency * 1000, specifier: "%.1f") ms")
                        .monospacedDigit()
                }
                LabeledContent("Output Channels") {
                    Text("\(session.outputNumberOfChannels)")
                }
            }

            if !measurements.isEmpty {
                Section("Results (\(measurements.count) samples)") {
                    LabeledContent("Average") {
                        Text("\(measurements.reduce(0, +) / Double(measurements.count), specifier: "%.1f") ms")
                            .monospacedDigit()
                    }
                    LabeledContent("Min") {
                        Text("\(measurements.min() ?? 0, specifier: "%.1f") ms")
                            .monospacedDigit()
                    }
                    LabeledContent("Max") {
                        Text("\(measurements.max() ?? 0, specifier: "%.1f") ms")
                            .monospacedDigit()
                    }
                }
            }

            Section {
                Button {
                    measureLatency()
                } label: {
                    HStack {
                        Image(systemName: "waveform.badge.magnifyingglass")
                        Text(isMeasuring ? "Measuring..." : "Measure Latency")
                    }
                }
                .disabled(isMeasuring)

                if !measurements.isEmpty {
                    Button("Clear Results", role: .destructive) {
                        measurements.removeAll()
                        currentLatency = 0
                    }
                }
            }
        }
        .navigationTitle("Audio Latency")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func measureLatency() {
        isMeasuring = true
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)
            try session.setPreferredIOBufferDuration(0.005)
        } catch {}

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let latency = (session.outputLatency + session.ioBufferDuration) * 1000.0
            currentLatency = latency
            measurements.append(latency)
            isMeasuring = false
        }
    }
}
