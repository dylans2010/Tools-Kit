import SwiftUI

@available(iOS 27.0, *)
struct SCKScreenRecorderView: View {
    @State private var sessionManager = RecordingSessionManager.shared
    @State private var captureManager = ScreenCaptureManager.shared

    var body: some View {
        VStack(spacing: 20) {
            if sessionManager.isRecording {
                Text("Recording: \(formatElapsedTime(sessionManager.elapsedTime))")
                    .font(.largeTitle.monospacedDigit())
                    .foregroundStyle(.red)

                Button(role: .destructive) {
                    Task { await stop() }
                } label: {
                    Label("Stop Recording", systemImage: "stop.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Text("Ready to Record")
                    .font(.title)

                Button {
                    captureManager.presentPicker()
                } label: {
                    Label("Select Screen", systemImage: "rectangle.badge.plus")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    start()
                } label: {
                    Label("Start Recording", systemImage: "record.circle")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(captureManager.filter == nil ? Color.gray : Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(captureManager.filter == nil)
            }
        }
        .padding()
        .navigationTitle("Screen Recorder")
    }

    private func start() {
        sessionManager.startRecording(featureType: .general)
    }

    private func stop() async {
        await sessionManager.stopRecording()
        try? await captureManager.stopCapture()
    }

    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

@available(iOS 27.0, *)
struct MeetingRecorderView: View {
    var body: some View {
        SCKGenericRecorderView(title: "Meeting Recorder", featureType: .meeting)
    }
}

@available(iOS 27.0, *)
struct PresentationRecorderView: View {
    var body: some View {
        SCKGenericRecorderView(title: "Presentation Recorder", featureType: .presentation)
    }
}

@available(iOS 27.0, *)
struct StudyModeView: View {
    var body: some View {
        SCKGenericRecorderView(title: "Study Mode", featureType: .study)
    }
}

@available(iOS 27.0, *)
struct TutorialCreatorView: View {
    var body: some View {
        SCKGenericRecorderView(title: "Tutorial Creator", featureType: .tutorial)
    }
}

@available(iOS 27.0, *)
struct SCKGenericRecorderView: View {
    let title: String
    let featureType: SCKFeatureType

    @State private var sessionManager = RecordingSessionManager.shared
    @State private var captureManager = ScreenCaptureManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.largeTitle.bold())

            if sessionManager.isRecording {
                Text("Session Active: \(formatElapsedTime(sessionManager.elapsedTime))")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.red)

                Button("Add Bookmark", systemImage: "bookmark.fill") {
                    sessionManager.addBookmark(title: "Auto-generated Bookmark")
                }
                .buttonStyle(.bordered)

                Button("Stop", role: .destructive) {
                    Task {
                        await sessionManager.stopRecording()
                        try? await captureManager.stopCapture()
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Start \(title)") {
                    captureManager.presentPicker()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle(title)
    }

    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
