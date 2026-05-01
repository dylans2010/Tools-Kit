import SwiftUI

struct MotionTrackingView: View {
    @StateObject private var manager = MotionTrackingManager.shared
    @State private var isTracking = false
    @State private var selectedPoint: CGPoint?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Motion Tracking").font(.headline)
                Spacer()
                Button(isTracking ? "Stop" : "Start Tracking") {
                    isTracking.toggle()
                }
                .buttonStyle(.bordered)
            }

            ZStack {
                // Mock Video Preview
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .frame(height: 200)
                    .cornerRadius(12)

                if let pos = selectedPoint {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .position(pos)
                }

                Text("Tap on an object to track")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        selectedPoint = value.location
                    }
            )

            if isTracking {
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Processing motion path...")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Target Layer").font(.caption.bold())
                HStack {
                    Image(systemName: "textformat")
                    Text("Callout Label")
                    Spacer()
                    Image(systemName: "link")
                        .foregroundColor(.blue)
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}
