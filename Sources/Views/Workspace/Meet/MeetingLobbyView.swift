/*
 * Summary: Pre-meeting lobby view with camera/mic check.
 * Changes: Implemented real participant presence, raw camera preview, and frosted UI.
 */

import SwiftUI
import AVFoundation

/// Lobby view for testing equipment and viewing participants before joining.
struct MeetingLobbyView: View {
    @ObservedObject var controller: MeetSessionController
    @State private var navigateToMeeting = false
    @State private var isCameraOn = true
    @State private var isMicOn = true

    var body: some View {
        VStack {
            ZStack {
                CameraPreviewView()
                    .ignoresSafeArea()
                    .blur(radius: 20)

                VStack(spacing: 30) {
                    Spacer()

                    cameraPreviewCard

                    controlsSection

                    participantsRoster

                    joinButton

                    Spacer()
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("Lobby")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToMeeting) {
            MeetingRoomView(controller: controller)
        }
        .task {
            await controller.runLobbyChecks()
        }
        .onChange(of: controller.phase) { newValue in
            if newValue == .inMeeting {
                navigateToMeeting = true
            }
        }
    }

    private var cameraPreviewCard: some View {
        VStack {
            if isCameraOn {
                CameraPreviewView()
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 240)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash.fill")
                                .font(.system(size: 40))
                            Text("Camera is off")
                                .font(.headline)
                        }
                        .foregroundColor(.secondary)
                    )
            }
        }
        .padding(.horizontal)
        .shadow(radius: 15)
    }

    private var controlsSection: some View {
        HStack(spacing: 40) {
            Button {
                withAnimation(.spring()) {
                    isMicOn.toggle()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: isMicOn ? "mic.fill" : "mic.slash.fill")
                        .font(.title)
                        .contentTransition(.symbolEffect(.replace))
                    Text(isMicOn ? "Mic On" : "Muted")
                        .font(.caption.bold())
                }
                .frame(width: 80)
                .padding()
                .background(isMicOn ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                .foregroundColor(isMicOn ? .blue : .red)
                .clipShape(Circle())
            }

            Button {
                withAnimation(.spring()) {
                    isCameraOn.toggle()
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: isCameraOn ? "video.fill" : "video.slash.fill")
                        .font(.title)
                        .contentTransition(.symbolEffect(.replace))
                    Text(isCameraOn ? "Camera On" : "Off")
                        .font(.caption.bold())
                }
                .frame(width: 80)
                .padding()
                .background(isCameraOn ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                .foregroundColor(isCameraOn ? .blue : .red)
                .clipShape(Circle())
            }
        }
    }

    private var participantsRoster: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In the meeting")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if controller.callManager.participants.isEmpty {
                        Text("No one here yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(controller.callManager.participants) { participant in
                            VStack {
                                Circle()
                                    .fill(Color.accentColor.gradient)
                                    .frame(width: 50, height: 50)
                                    .overlay(Text(participant.userName.prefix(1)).foregroundColor(.white))
                                Text(participant.userName)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Material.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private var joinButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            Task {
                await controller.startMeeting()
            }
        } label: {
            Text("Join Meeting")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(Capsule())
                .shadow(color: .accentColor.opacity(0.3), radius: 10, y: 5)
        }
        .padding(.horizontal, 40)
    }
}

/// Raw AVCaptureSession preview for camera checks.
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        Task.detached {
            session.startRunning()
        }

        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
