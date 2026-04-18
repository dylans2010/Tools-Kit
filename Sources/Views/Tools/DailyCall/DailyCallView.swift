import SwiftUI

#if canImport(Daily)
import Daily
#endif

struct DailyCallView: View {
    @StateObject private var backend = DailyCallBackend()

    var body: some View {
        Form {
            Section(header: Text("Room")) {
                TextField("https://your-team.daily.co/room-name", text: $backend.roomURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                SecureField("Meeting token (optional)", text: $backend.meetingToken)
                TextField("Display name", text: $backend.username)
            }

            Section(header: Text("Session")) {
                HStack {
                    Label(backend.callStateDescription, systemImage: backend.isJoined ? "dot.radiowaves.left.and.right" : "phone.down")
                        .foregroundColor(backend.isJoined ? .green : .secondary)
                    Spacer()
                    if backend.isJoining {
                        ProgressView()
                    }
                }

                HStack {
                    Button("Join") {
                        Task { await backend.join() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(backend.isJoining || backend.isJoined)

                    Button("Leave") {
                        Task { await backend.leave() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!backend.isJoined)
                }

                HStack {
                    Button(backend.isMicrophoneEnabled ? "Mute Mic" : "Unmute Mic") {
                        Task { await backend.toggleMicrophone() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!backend.isJoined)

                    Button(backend.isCameraEnabled ? "Disable Cam" : "Enable Cam") {
                        Task { await backend.toggleCamera() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(!backend.isJoined)
                }
            }

            #if canImport(Daily)
            Section(header: Text("Video")) {
                if let track = backend.activeSpeakerVideoTrack ?? backend.localVideoTrack {
                    DailySDKVideoView(track: track)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ContentUnavailableView("No Video Track", systemImage: "video.slash", description: Text("Join a room and enable camera to render video."))
                }
            }
            #endif

            Section(header: Text("Participants")) {
                if backend.participants.isEmpty {
                    Text("No participants")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(backend.participants) { participant in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(participant.name)
                                Text(participant.id)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if participant.isLocal {
                                Text("You")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: participant.isAudioPlayable ? "mic.fill" : "mic.slash.fill")
                            Image(systemName: participant.isVideoPlayable ? "video.fill" : "video.slash.fill")
                        }
                    }
                }
            }

            Section(header: Text("Debug")) {
                LabeledContent("Network", value: backend.networkQualityDescription)
                LabeledContent("Recording", value: backend.recordingStateDescription)
                if let errorMessage = backend.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                ForEach(backend.eventLog.prefix(30), id: \.self) { line in
                    Text(line)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle("Daily Call")
    }
}

#if canImport(Daily)
private struct DailySDKVideoView: UIViewRepresentable {
    let track: VideoTrack

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        view.videoScaleMode = .fit
        return view
    }

    func updateUIView(_ uiView: VideoView, context: Context) {
        if uiView.track !== track {
            uiView.track = track
        }
    }
}
#endif

struct DailyCallTool: Tool {
    let name = "Daily Call"
    let icon = "video.badge.waveform"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Join Daily.co video rooms with live participants and diagnostics"
    let requiresAPI = false
    var view: AnyView { AnyView(DailyCallView()) }
}
