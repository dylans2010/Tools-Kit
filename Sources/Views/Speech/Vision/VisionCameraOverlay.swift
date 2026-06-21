import SwiftUI
import AVFoundation

struct VisionCameraOverlay: View {
    let session: AVCaptureSession
    @StateObject private var visionService = CloudVisionService.shared
    @StateObject private var sessionManager = SpeechSessionManager.shared

    var body: some View {
        ZStack {
            AVFoundationCameraPreview(session: session)
                .ignoresSafeArea()

            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.black.opacity(0.4), .clear, .black.opacity(0.4)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    VisionStatusBadge(isProcessing: visionService.isProcessing)
                    Spacer()
                    
                    // Pause / Resume Toggle
                    Button(action: {
                        sessionManager.cameraManager.togglePause()
                    }) {
                        Image(systemName: sessionManager.cameraManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .foregroundColor(sessionManager.cameraManager.isPaused ? .green : .orange)
                    }
                    
                    // Switch Camera Button
                    Button(action: {
                        SpeechSessionManager.shared.cameraManager.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate.fill")
                            .font(.title2)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()
                
                // Subtitles for AI response
                if let lastAssistant = sessionManager.messages.last(where: { $0.role == .assistant }) {
                    Text(lastAssistant.content)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }

                if visionService.isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(.white)
                        Text("Analyzing surroundings...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .padding(.bottom, 100)
                } else {
                    // Tap to analyze button
                    Button(action: {
                        sessionManager.cameraManager.captureImmediateFrame()
                    }) {
                        Text("Tap to Analyze")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor.opacity(0.8))
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct VisionStatusBadge: View {
    let isProcessing: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isProcessing ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
                .shadow(color: isProcessing ? .orange : .green, radius: 4)

            Text(isProcessing ? "PROCESSING" : "LIVE")
                .font(.caption2.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}
