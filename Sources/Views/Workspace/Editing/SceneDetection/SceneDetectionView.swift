import SwiftUI

struct SceneDetectionView: View {
    @StateObject private var manager = SceneDetectionManager.shared
    @State private var isAnalyzing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Scene Detection").font(.headline)
                Spacer()
                Button("Run Detection") { performDetection() }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAnalyzing)
            }

            if isAnalyzing {
                HStack {
                    ProgressView()
                    Text("Analyzing video content...")
                        .font(.caption)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(manager.detectedScenes) { scene in
                        SceneThumbnail(scene: scene)
                    }

                    if !isAnalyzing && manager.detectedScenes.isEmpty {
                        Text("No scenes detected yet.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
        }
        .padding()
        .background(Color.workspaceSurface)
        .cornerRadius(12)
    }

    private func performDetection() {
        isAnalyzing = true
        // Mock detection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            manager.detectedScenes = [
                DetectedScene(startTime: 0, endTime: 12.5, confidence: 0.98),
                DetectedScene(startTime: 12.5, endTime: 24.1, confidence: 0.95, isHighlight: true),
                DetectedScene(startTime: 24.1, endTime: 45.0, confidence: 0.92)
            ]
            isAnalyzing = false
        }
    }
}

struct SceneThumbnail: View {
    let scene: DetectedScene

    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 80)
                .overlay {
                    if scene.isHighlight {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .padding(4)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                            .offset(x: 45, y: -25)
                    }
                }

            Text("\(String(format: "%.1fs", scene.startTime)) - \(String(format: "%.1fs", scene.endTime))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
