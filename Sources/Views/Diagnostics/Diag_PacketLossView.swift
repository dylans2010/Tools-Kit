import SwiftUI

struct Diag_PacketLossView: View {
    @State private var lossPercentage: Double = 0.5
    @State private var jitter: Double = 4.2
    @State private var isTesting = false

    var body: some View {
        List {
            Section("Live Stats") {
                VStack(spacing: 20) {
                    HStack {
                        VStack {
                            Text("\(lossPercentage, specifier: "%.1f")%")
                                .font(.system(size: 34, weight: .bold, design: .monospaced))
                                .foregroundStyle(lossPercentage > 2 ? .red : .green)
                            Text("Packet Loss")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text("\(jitter, specifier: "%.1f") ms")
                                .font(.system(size: 34, weight: .bold, design: .monospaced))
                                .foregroundStyle(jitter > 20 ? .orange : .blue)
                            Text("Jitter")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
            }

            Section("Ping History") {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(0..<40) { _ in
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 4, height: CGFloat.random(in: 20...60))
                    }
                }
                .frame(height: 60)
            }

            Section {
                Button(action: startTest) {
                    if isTesting {
                        ProgressView()
                    } else {
                        Text("Start Measurement")
                    }
                }
            }
        }
        .navigationTitle("Packet Loss")
    }

    private func startTest() {
        isTesting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isTesting = false
        }
    }
}
