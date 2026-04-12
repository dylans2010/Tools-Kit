import SwiftUI

struct NetworkSpeedTool: Tool {
    let name = "Network Speed"
    let icon = "wifi"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Test your device's download speed, upload speed, and ping"
    let requiresAPI = false
    var view: AnyView { AnyView(NetworkSpeedView()) }
}

struct NetworkSpeedView: View {
    @StateObject private var backend = NetworkSpeedBackend()

    var body: some View {
        ToolDetailView(tool: NetworkSpeedTool()) {
            VStack(spacing: 32) {
                // Gauge Display
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray6), lineWidth: 20)
                        .frame(width: 250, height: 250)

                    Circle()
                        .trim(from: 0, to: CGFloat(min(backend.downloadSpeed / 200.0, 1.0)))
                        .stroke(
                            AngularGradient(gradient: Gradient(colors: [.blue, .cyan, .green]), center: .center),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 250, height: 250)
                        .animation(.easeInOut(duration: 1.0), value: backend.downloadSpeed)

                    VStack(spacing: 4) {
                        Text("\(Int(backend.downloadSpeed))")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                        Text("Mbps")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Download")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .bold()
                    }
                }

                HStack(spacing: 40) {
                    VStack {
                        Text("Upload")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", backend.uploadSpeed))
                            .font(.title2.bold())
                            .foregroundColor(.green)
                        Text("Mbps")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("Ping")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(backend.ping)")
                            .font(.title2.bold())
                            .foregroundColor(.orange)
                        Text("ms")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    Task {
                        await backend.runTest()
                    }
                }) {
                    if backend.isTesting {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Testing...")
                        }
                    } else {
                        Text("Start Speed Test")
                            .bold()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(backend.isTesting)

                if !backend.history.isEmpty {
                    ToolInputSection("Recent History") {
                        ForEach(backend.history) { result in
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.blue)
                                Text("\(Int(result.download))")
                                    .bold()
                                Text("Mbps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Image(systemName: "timer")
                                    .foregroundColor(.orange)
                                Text("\(result.ping)ms")
                                    .font(.caption)
                            }
                            .padding()
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
