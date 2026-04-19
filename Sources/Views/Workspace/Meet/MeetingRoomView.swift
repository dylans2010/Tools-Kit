/*
 * Summary: Main call view with native video rendering.
 * Changes: Implemented native video grid, custom toolbar, and sheet management.
 */

import SwiftUI
import Daily

/// Main view for an active meeting call.
struct MeetingRoomView: View {
    @ObservedObject var controller: MeetSessionController
    @State private var showingChat = false
    @State private var showingAdmin = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                participantGrid

                bottomToolbar
            }

            if controller.unreadMessageCount > 0 {
                unreadBadge
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingChat) {
            MeetingChatView(controller: controller)
                .onAppear { controller.unreadMessageCount = 0 }
        }
        .sheet(isPresented: $showingAdmin) {
            AdminControlsView(controller: controller)
        }
        .sheet(isPresented: $showingSettings) {
            MeetingSettingsView(settings: $controller.settings)
        }
    }

    private var participantGrid: some View {
        ScrollView {
            let participants = controller.callManager.participants
            let local = controller.callManager.localParticipant

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let local = local {
                    ParticipantVideoView(participant: local)
                        .frame(height: 180)
                }

                ForEach(participants) { participant in
                    ParticipantVideoView(participant: participant)
                        .frame(height: 180)
                }
            }
            .padding()
        }
    }

    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            toolbarButton(icon: controller.callManager.isMuted ? "mic.slash.fill" : "mic.fill", color: controller.callManager.isMuted ? .red : .blue) {
                Task { await controller.callManager.toggleMute() }
            }

            toolbarButton(icon: controller.callManager.isCameraOff ? "video.slash.fill" : "video.fill", color: controller.callManager.isCameraOff ? .red : .blue) {
                Task { await controller.callManager.toggleCamera() }
            }

            toolbarButton(icon: "message.fill", color: .gray) {
                showingChat = true
            }

            toolbarButton(icon: "person.badge.shield.checkmark.fill", color: .gray) {
                showingAdmin = true
            }

            toolbarButton(icon: "phone.down.fill", color: .red) {
                Task { await controller.leaveMeeting() }
            }
        }
        .padding()
        .background(Material.ultraThinMaterial)
    }

    private func toolbarButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
        }
    }

    private var unreadBadge: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(controller.unreadMessageCount)")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: -60, y: 20)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

/// View for individual participant video and metadata.
struct ParticipantVideoView: View {
    let participant: DailyParticipant

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let track = participant.videoTrack, !participant.isCameraOff {
                DailyVideoView(track: track)
                    .background(Color.gray.opacity(0.3))
            } else {
                Color.gray.opacity(0.8)
                    .overlay(
                        VStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 60, height: 60)
                                .overlay(Text(participant.userName.prefix(1)).font(.title).foregroundColor(.white))
                            Text(participant.userName)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    )
            }

            HStack {
                Text(participant.userName)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)

                if participant.isMuted {
                    Image(systemName: "mic.slash.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(8)
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

/// Native VideoView wrapper for Daily tracks.
struct DailyVideoView: UIViewRepresentable {
    let track: VideoTrack

    func makeUIView(context: Context) -> VideoView {
        let videoView = VideoView()
        videoView.videoScaleMode = .fit
        return videoView
    }

    func updateUIView(_ uiView: VideoView, context: Context) {
        if uiView.track !== track {
            uiView.track = track
        }
    }
}
