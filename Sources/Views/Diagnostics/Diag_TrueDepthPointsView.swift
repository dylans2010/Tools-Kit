import SwiftUI

struct Diag_TrueDepthPointsView: View {
    @State private var isActive = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            .frame(width: 280, height: 280)

                        if isActive {
                            PointCloudSim()
                        } else {
                            Image(systemName: "faceid")
                                .font(.system(size: 80))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                }
            }

            Section("Sensor Information") {
                LabeledContent("Dot Projector", value: "Active")
                LabeledContent("IR Camera", value: "30 FPS")
                LabeledContent("Point Density", value: "30,000 dots")
            }

            Section {
                Button(action: { isActive.toggle() }) {
                    Text(isActive ? "Stop Projection" : "Start TrueDepth View")
                }
            }
        }
        .navigationTitle("TrueDepth Cloud")
    }
}

struct PointCloudSim: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<500 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let dist = sqrt(pow(x - size.width/2, 2) + pow(y - size.height/2, 2))
                if dist < 140 {
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(.blue))
                }
            }
        }
    }
}
