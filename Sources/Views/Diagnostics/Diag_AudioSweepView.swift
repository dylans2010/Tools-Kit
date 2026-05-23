import SwiftUI

struct Diag_AudioSweepView: View {
    @State private var frequency: Double = 440
    @State private var isPlaying = false

    var body: some View {
        List {
            Section("Tone Generator") {
                VStack(spacing: 20) {
                    Text("\(Int(frequency)) Hz")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))

                    Slider(value: $frequency, in: 20...20000, step: 1)

                    HStack {
                        Text("20Hz")
                        Spacer()
                        Text("20kHz")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical)
            }

            Section {
                Button(action: { isPlaying.toggle() }) {
                    HStack {
                        Spacer()
                        Label(isPlaying ? "Stop Sweep" : "Start Sweep", systemImage: isPlaying ? "stop.fill" : "play.fill")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(isPlaying ? .red : .blue)
            }

            Section(footer: Text("Warning: Avoid high volume when testing high frequencies. Use to test speaker range and distortion.")) {
                EmptyView()
            }
        }
        .navigationTitle("Frequency Sweep")
    }
}
