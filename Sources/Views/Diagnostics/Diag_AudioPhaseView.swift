import SwiftUI

struct Diag_AudioPhaseView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Speaker Phase Correlation")
                .font(.headline)

            HStack(spacing: 40) {
                VStack {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.largeTitle)
                    Text("Left")
                }

                Image(systemName: "arrow.left.and.right")
                    .font(.title)
                    .foregroundStyle(.green)

                VStack {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.largeTitle)
                    Text("Right")
                }
            }
            .padding()

            List {
                Section("Phase Analysis") {
                    LabeledContent("Correlation", value: "0.98")
                    LabeledContent("Phase Offset", value: "2.1°")
                    LabeledContent("Status", value: "In-Phase")
                }
            }
        }
        .navigationTitle("Audio Phase Test")
    }
}
