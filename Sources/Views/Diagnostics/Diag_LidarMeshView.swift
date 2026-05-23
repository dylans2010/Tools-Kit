import SwiftUI

struct Diag_LidarMeshView: View {
    @State private var isScanning = false
    @State private var pointCount: Int = 0

    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black)
                            .frame(height: 300)

                        if isScanning {
                            LidarSimulation()
                        } else {
                            VStack {
                                Image(systemName: "dot.radiowaves.up.forward")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.blue)
                                Text("Scanner Ready")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }

            Section("Mesh Stats") {
                LabeledContent("Vertices", value: "\(pointCount)")
                LabeledContent("Triangles", value: "\(pointCount / 3)")
                LabeledContent("Resolution", value: "5mm")
            }

            Section {
                Button(action: {
                    isScanning.toggle()
                    if isScanning {
                        simulatePoints()
                    }
                }) {
                    Text(isScanning ? "Stop Mesh Capture" : "Start LiDAR Scan")
                }
            }
        }
        .navigationTitle("LiDAR Mesh")
    }

    private func simulatePoints() {
        pointCount = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isScanning { timer.invalidate(); return }
            pointCount += Int.random(in: 100...500)
            if pointCount > 50000 { timer.invalidate() }
        }
    }
}

struct LidarSimulation: View {
    @State private var phase = 0.0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<100 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let alpha = sin(now * 2 + Double(i)) * 0.5 + 0.5
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(.blue.opacity(alpha)))
                }
            }
        }
    }
}
